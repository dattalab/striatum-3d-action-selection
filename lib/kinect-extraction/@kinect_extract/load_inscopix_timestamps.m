function load_inscopix_timestamps(OBJ, pth)
%
%
%
%
%

for i = 1:length(OBJ)

    if nargin > 1
        [nidaq_data, nidaq_ts] = OBJ(i).load_nidaq(pth);
    elseif OBJ(i).files.nidaq{2}
        [nidaq_data, nidaq_ts] = OBJ(i).load_nidaq;
    else
        OBJ(i).timestamps.inscopix = [];
        continue;
    end

    if ~isfield(OBJ(i).metadata.extract, 'NidaqSamplingRate')
        nidaq_fs = 1 ./ mean(diff(nidaq_ts));
    else
        nidaq_fs = OBJ(i).metadata.extract.NidaqSamplingRate;
    end

    idx = 1:size(nidaq_data, 1) - 1;
    insc_frame_onsets = find([false; nidaq_data(idx, 1) < .5 & nidaq_data(idx + 1, 1) >= .5]);

    df_onsets = diff(insc_frame_onsets);

    % glitches are substantially shorter than 25 msec

    df_onsets2 = find(df_onsets < .0246 * nidaq_fs);
    del_idx = df_onsets2(find(diff(df_onsets2) == 1) + 1);
    insc_frame_onsets(del_idx) = [];

    %insc_frame_onsets=insc_frame_onsets([1 find(diff(insc_frame_onsets)>round(nidaq_fs*.0164))'+1]);

    insc_frame_onsets_nidaq = nidaq_ts(insc_frame_onsets);

    % removes any positive going edges if the previous pause was shorter than 10 msec (should be 15 msec total)

    %nidaq_fs=1./mean(diff(nidaq_ts));

    % now get Kinect timestamps from nidaq and match up

    inscopix_frame_idx = zeros(OBJ(i).metadata.nframes, 1);
    dist = zeros(OBJ(i).metadata.nframes, 1);
    upd = kinect_extract.proc_timer(length(dist), 'frequency', 1e2);

    if isempty(insc_frame_onsets_nidaq)
        OBJ(i).timestamps.inscopix = [];
        continue;
    end

    for j = 1:length(dist)
        [dist(j), inscopix_frame_idx(j)] = min(abs(OBJ(i).timestamps.depth(j, 2) - insc_frame_onsets_nidaq));
        upd(j);
    end

    inscopix_frame_idx(abs(dist) > .018) = nan;

    % get timestamps and remaining data

    OBJ(i).timestamps.inscopix = inscopix_frame_idx;

end

end % function

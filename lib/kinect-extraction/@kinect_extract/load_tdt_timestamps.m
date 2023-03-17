function STATUS = load_tdt_timestamps(OBJ, NI_CH, TDT_SYNC, THRESH)
% takes sync data (must be a pulse train)
%
%
%

STATUS = true;
eps = 1;

if nargin < 4
    THRESH = .25;
end

% give the user the option to use an arbitrary signal here...

fprintf('Loading NIDAQ sync signal on channel %i\n', NI_CH);
[ni_data, ni_ts] = OBJ.load_nidaq;
ni_sync = ni_data(:, NI_CH);
ni_fs = OBJ.metadata.extract.NidaqSamplingRate;

fprintf('Scanning NI pulse train...');

[ni_pulsenum, ni_pulsepos, ni_pos_sample] = kinect_extract.scan_pulse_train(ni_sync, THRESH);

fprintf('success.\n');

if OBJ.metadata.tdt{1}.status.sampling_rate ~= OBJ.metadata.extract.NidaqSamplingRate
    % do some resampling, whatevas

    fprintf('Resampling TDT signal...\n');
    [p, q] = rat(OBJ.metadata.extract.NidaqSamplingRate / OBJ.metadata.tdt{1}.status.sampling_rate);

    for i = 1:length(TDT_SYNC)
        TDT_SYNC{i} = resample(TDT_SYNC{i}, p, q);
    end

end

% scan the pulse trains for pulse number and position within each pulse
% loop through files in case there is more than 1

fprintf('Scanning TDT pulse train...');
startcount = 0;
tdt_pulsenum = cell(1, numel(TDT_SYNC));
tdt_pulsepos = cell(size(tdt_pulsenum));

for i = 1:numel(TDT_SYNC)
    [tdt_pulsenum{i}, tdt_pulsepos{i}] = kinect_extract.scan_pulse_train(TDT_SYNC{i}, THRESH, startcount);
    startcount = max(tdt_pulsenum{i});
end

if isempty(tdt_pulsenum)
    STATUS = false;
    return;
end

fprintf('Found %i pulses in TDT signal\n', max(tdt_pulsenum{end}));

% if there's only 1 tdt file and multiple pulse trains, use the one that matches

gaps = find(diff(ni_pos_sample) > ni_fs * 20);

if length(TDT_SYNC) == 1 & length(gaps) == 1
    fprintf('Multiple pulse groups detected with one TDT file, scanning for best match...\n');

    new_data1 = zeros(size(ni_data));
    new_data2 = zeros(size(new_data1));
    group1 = 1:ni_pos_sample(gaps(1));
    group2 = (ni_pos_sample(gaps(1) + 1)):length(ni_data);
    new_data1(group1) = ni_data(group1);
    new_data2(group2) = ni_data(group2);

    [ni_pulsenum1, ni_pulsepos1] = kinect_extract.scan_pulse_train(new_data1, THRESH);
    [ni_pulsenum2, ni_pulsepos2] = kinect_extract.scan_pulse_train(new_data2, THRESH);

    fprintf('Group 1:  %i pulses\nGroup 2:  %i pulses\n', max(ni_pulsenum1), max(ni_pulsenum2));

    if max(ni_pulsenum1) == max(tdt_pulsenum{end})
        ni_pulsenum = ni_pulsenum1;
        ni_pulsepos = ni_pulsepos1;
    elseif max(ni_pulsenum2) == max(tdt_pulsenum{end})
        ni_pulsenum = ni_pulsenum2;
        ni_pulsepos = ni_pulsepos2;
    else
        fprintf('Could not find a match, bailing...\n')
        STATUS = false;
        return;
    end

elseif length(gaps) > 1
    fprintf('More than two groups not currently supported\n');
    STATUS = false;
end

fprintf('success.\n');

if max(ni_pulsenum) ~= max(tdt_pulsenum{end})
    fprintf('NI pulse number not equal to TDT pulse number %s\n', max(ni_pulsenum), max(tdt_pulsenum{end}));
    STATUS = false;
    return;
end

OBJ.timestamps.tdt = cell(size(tdt_pulsenum));

% now for each tdt sample we have a unique pulsenum and pulsepos, match to NI!

remove_idx = ni_pulsenum == 0;
ni_pulsenum(remove_idx) = [];
ni_pulsepos(remove_idx) = [];
ni_ts(remove_idx) = [];

for i = 1:length(tdt_pulsenum)

    timer_upd = kinect_extract.proc_timer(length(TDT_SYNC{i}), 'frequency', 10000);

    match_idx = 1;
    OBJ.timestamps.tdt{i} = nan(size(TDT_SYNC{i}));

    for j = 1:length(TDT_SYNC{i})

        if (tdt_pulsenum{i}(j) == 0)
            continue;
        end

        % only scan a small amount to the left and right, otherwise it takes FUHEVER

        pulsenum_idx = find(ni_pulsenum(match_idx:min(match_idx + 100, length(ni_pulsenum))) == tdt_pulsenum{i}(j));

        if isempty(pulsenum_idx)
            pulsenum_idx = find(ni_pulsenum == tdt_pulsenum{i}(j));
        end

        pulsepos = ni_pulsepos(pulsenum_idx);
        [val, loc] = min(abs(pulsepos - tdt_pulsepos{i}(j)));
        match_idx = match_idx + (min(pulsenum_idx) - 1) + (loc - 1);

        % if we exceed a tolerance, drop in a nan

        OBJ.timestamps.tdt{i}(j) = ni_ts(match_idx);
        timer_upd(j);

    end

end

fprintf('\n\n');

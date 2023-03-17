function INSC_DATA = get_inscopix_timebase(OBJ, DATA, FRAMES)
%% inputs
% data : kinect_extract data that you want on inscopix timebase
% frames : the frames (indices if you want) of the inscopix data
%	puts kinect_extract data into inscopix timebase
%

% mean for floats, mode for integer (likely behavior labels)
if isfloat(DATA)
    fprintf('Will use mean for binning...\n');
    downfun = @(x) mean(x);
elseif isinteger(DATA)
    fprintf('Will use mode for binning...\n');
    downfun = @(x) mode(x);
end

% closest inscopix frame per Kinect frame

ts = OBJ.timestamps.inscopix;
[uniq_ts, ~, uniq_idx] = unique(ts);
uniq_ts(isnan(uniq_ts)) = [];

if isvector(DATA)

    INSC_DATA = nan(length(FRAMES), 1);
    upd = kinect_extract.proc_timer(length(uniq_ts), 'frequency', 1e2);

    for i = 1:length(uniq_ts)
        INSC_DATA(uniq_ts(i)) = downfun(DATA(ts == uniq_ts(i)));
        upd(i);
    end

elseif ndims(DATA) == 2

    INSC_DATA = nan(length(FRAMES), size(DATA, 2));
    upd = kinect_extract.proc_timer(length(uniq_ts), 'frequency', 1e2);

    for i = 1:length(uniq_ts)

        if sum(ts == uniq_ts(i)) > 1
            INSC_DATA(uniq_ts(i), :) = downfun(DATA(ts == uniq_ts(i), :));
        else
            INSC_DATA(uniq_ts(i), :) = DATA(ts == uniq_ts(i), :);
        end

        upd(i);
    end

end

function DIST = check_timing(OBJ, LED_TRACE, MISC_TRACES, MISC_TS)
% Assumes you're blinking an IR LED and copying the voltage to the NIDAQ
%
%
%

if nargin < 4
    MISC_TS = [];
end

if nargin < 3
    MISC_TRACES = [];
end

if ~isa(LED_TRACE, 'double')
    LED_TRACE = double(LED_TRACE(:));
end

% nidaq data should have the voltage copied
nanzscore = @(x) (x - nanmean(x)) ./ nanstd(x);

[led_command, led_command_ts] = OBJ.load_nidaq;
led_command = led_command(:, 1);

% now compare our many ways of looking at timestamps

nidaq_ts = OBJ.timestamps.depth(:, 2);
kinect_ts = OBJ.timestamps.depth(:, 1);
shift_ts = smooth(nidaq_ts - kinect_ts, 100, 'loess');
kinect_ts_corrected = shift_ts + kinect_ts;

% threshold crossings, voltage

led_command_idx = 1:length(led_command) - 1;
led_command_poscross = led_command(led_command_idx) < .1 & led_command(led_command_idx + 1) >= .1;
DIST.led_command_poscross_ts = led_command_ts(led_command_poscross);

led_trace = medfilt1(nanzscore(LED_TRACE), 5);
led_trace_idx = 1:length(led_trace) - 1;
led_image_poscross = led_trace(led_trace_idx) <- .5 & led_trace(led_trace_idx + 1) >= - .5;
DIST.led_image_poscross_nidaq_ts = nidaq_ts(led_image_poscross);
DIST.led_image_poscross_kinect_ts = kinect_ts(led_image_poscross);

DIST.nidaq_ts = nan(length(find(led_command_poscross)), 1);
missing_frames = [0; diff(kinect_ts)];
DIST.led_image_poscross_idx = find(led_image_poscross);

counter = 1;

for i = 1:length(DIST.led_image_poscross_nidaq_ts)
    diffs = (DIST.led_image_poscross_nidaq_ts(i) - nidaq_ts(1)) - (DIST.led_command_poscross_ts - nidaq_ts(1));
    [~, loc] = min(abs(diffs));
    DIST.nidaq_ts(i) = diffs(loc);
end

DIST.nidaq_ts_corrected = nan(length(find(led_command_poscross)), 1);
DIST.nidaq_ts_diff = nan(length(find(led_command_poscross)), 1);

DIST.led_image_poscross_kinect_ts_corrected = kinect_ts_corrected(led_image_poscross);

for i = 1:length(DIST.led_image_poscross_nidaq_ts)
    diffs = (DIST.led_image_poscross_kinect_ts_corrected(i) - nidaq_ts(1)) - (DIST.led_command_poscross_ts - nidaq_ts(1));
    [~, loc] = min(abs(diffs));
    DIST.nidaq_ts_corrected(i) = diffs(loc);
    %DIST.missing_frames(i)=sum(missing_frames(led_image_poscross_idx(i)-20:led_image_poscross_idx(i)+20));
end

if ~isempty(MISC_TRACES) & ~isempty(MISC_TS)
    idx = 1:length(MISC_TRACES) - 1;
    MISC_TRACES = nanzscore(double(MISC_TRACES(:)));
    misc_poscross = MISC_TRACES(idx) < 0 & MISC_TRACES(idx + 1) >= 0;
    DIST.misc_poscross_ts = MISC_TS(misc_poscross);
    DIST.misc_ts = nan(length(find(misc_poscross)), 1);

    for i = 1:length(find(misc_poscross))
        diffs = (DIST.misc_poscross_ts(i) - min(MISC_TS)) - (DIST.led_image_poscross_kinect_ts_corrected - min(MISC_TS));
        [~, loc] = min(abs(diffs));
        DIST.misc_poscross_ts(i) = diffs(loc);
    end

end

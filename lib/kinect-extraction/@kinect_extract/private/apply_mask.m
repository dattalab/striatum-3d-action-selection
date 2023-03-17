function FRAMES = kinect_roi_apply_mask(FRAMES, MASK, varargin)
%
% given mask and MOVIE, extract ROI time trace

% mult., froeb norm.
% TODO: counter

frame_stride = 500;
nparams = length(varargin);
mem_var = 'depth_data_masked';

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

for i = 1:2:nparams

    switch lower(varargin{i})
        case 'mem_var'
            mem_var = varargin{i + 1};
        case 'frame_stride'
            frame_stride = varargin{i + 1};
        otherwise
    end

end

% need to check re: memmapfile here so we don't load everything into memory
ismemmap = false;

if strcmp(class(FRAMES), 'matlab.io.MatFile')
    [height, width, nframes] = size(FRAMES, mem_var);
    ismemmap = true;
    FRAMES.Properties.Writable = true;
else
    [height, width, nframes] = size(FRAMES);
end

steps = 0:frame_stride:nframes;
steps = unique([steps nframes]);

timer_upd = kinect_extract.proc_timer(length(steps) - 1);

for i = 1:length(steps) - 1

    use_frames = length(steps(i) + 1:steps(i + 1));

    if ismemmap
        FRAMES.(mem_var)(:, :, steps(i) + 1:steps(i + 1)) = ...
            FRAMES.(mem_var)(:, :, steps(i) + 1:steps(i + 1)) .* int16(repmat(MASK, [1 1 use_frames]));
    else
        FRAMES(:, :, steps(i) + 1:steps(i + 1)) = FRAMES(:, :, steps(i) + 1:steps(i + 1)) .* int16(repmat(MASK, [1 1 use_frames]));
    end

    timer_upd(i);

end

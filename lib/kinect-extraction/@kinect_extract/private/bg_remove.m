function [FRAMES, BG] = kinect_BG_remove(FRAMES, varargin)
%

frame_stride = 500;
eta_counter = 4;
eta_buffer = 3;
use_frames = 3e3;
mouse_floor = 5;
filt_size = [7 7];
nparams = length(varargin);
mem_var = 'depth_masked';

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

for i = 1:2:nparams

    switch lower(varargin{i})
        case 'mouse_floor'
            mouse_floor = varargin{i + 1};
        case 'filt_size'
            filt_size = varargin{i + 1};
        case 'use_frames'
            use_frames = varargin{i + 1};
        case 'mem_var'
            mem_var = varargin{i + 1};
        case 'frame_stride'
            frame_stride = varargin{i + 1};
        otherwise
    end

end

ismemmap = false;

if strcmp(class(FRAMES), 'matlab.io.MatFile')
    [height, width, nframes] = size(FRAMES, mem_var);
    ismemmap = true;
    FRAMES.Properties.Writable = true;
else
    [height, width, nframes] = size(FRAMES);
end

if nframes <= use_frames
    bg_frames = 1:nframes;
else
    bg_frames = 1:round(nframes / use_frames):nframes;
end

if ismemmap
    BG = medfilt2(median(FRAMES.(mem_var)(:, :, bg_frames), 3), filt_size);
    FRAMES.bg_image = BG;
else
    BG = medfilt2(median(FRAMES(:, :, bg_frames), 3), filt_size);
end

steps = 0:frame_stride:nframes;
steps = unique([steps nframes]);
timer_upd = kinect_extract.proc_timer(length(steps) - 1);

for i = 1:length(steps) - 1

    nframes_proc = length(steps(i) + 1:steps(i + 1));

    if ismemmap
        tmp = FRAMES.(mem_var)(:, :, steps(i) + 1:steps(i + 1));
    else
        tmp = FRAMES(:, :, steps(i) + 1:steps(i + 1));
    end

    % set low values to zero (leave in high values for cable removal)

    tmp = repmat(BG, [1 1 nframes_proc]) - tmp;
    tmp(tmp < mouse_floor) = 0;

    if ismemmap
        FRAMES.(mem_var)(:, :, steps(i) + 1:steps(i + 1)) = tmp;
    else
        FRAMES(:, :, steps(i) + 1:steps(i + 1)) = tmp;
    end

    timer_upd(i);

end

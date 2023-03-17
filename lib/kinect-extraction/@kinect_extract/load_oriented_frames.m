function BOUNDED_FRAMES = load_oriented_frames(OBJ, varargin)
%load_oriented_frames- Loads cropped, oriented frames from a given kinect_extract object.
%
% Usage: obj.load_oriented_frames(varargin)
%
% note that ONLY SINGLE OBJECTS can be used with this method
%
% Inputs:
%   None
%
% Outputs:
%   bounded_frames (h x w x frames): 3d array of cropped-oriented frames
%
% Options (parameter/value pairs):
%   raw (bool): load raw data (default: false)
%   use_transform (bool): use affine transform (default: false)
%   missing_value (float): what to set missing data to (default: nan)
%   process_frames (bool): filter frames (default: true)
%   use_mask (bool): use mouse mask or cable mask to set mouse/non-mouse pixels (default: true)
%   frame_idx (array): frames to load
%
% Example:
%   frames=obj.load_oriented_frames('raw','frame_idx',[1:1e3]) % loads the first 1000 frames, raw
%

opts = struct( ...
    'raw', false, ...
    'use_transform', false, ...
    'missing_value', nan, ...
    'process_frames', true, ...
    'use_mask', true, ...
    'frame_idx', []);

opts_names = fieldnames(opts);
nparams = length(varargin);

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

for i = 1:2:nparams

    if any(strcmp(varargin{i}, opts_names))
        opts.(varargin{i}) = varargin{i + 1};
    end

end

if ~OBJ.status.orient
    fprintf('Need to orient data before loading oriented frames...\n');
    return;
end

% TODO allow for some image filtering...

if OBJ.has_cable & ~opts.raw

    if isempty(opts.frame_idx)
        load(OBJ.files.orient{1}, 'depth_bounded_rotated', 'depth_bounded_cable_mask_rotated');
    else
        m = matfile(OBJ.files.orient{1});
        depth_bounded_rotated = m.depth_bounded_rotated(:, :, opts.frame_idx);
        depth_bounded_cable_mask_rotated = m.depth_bounded_cable_mask_rotated(:, :, opts.frame_idx);
        clear m;
    end

    if opts.use_transform & OBJ.status.has_transform
        depth_bounded_rotated = ...
            imwarp(depth_bounded_rotated, OBJ.transform, 'OutputView', imref2d(OBJ.options.common.box_size));
        depth_bounded_cable_mask_rotated = ...
            imwarp(depth_bounded_cable_mask_rotated, OBJ.transform, 'OutputView', imref2d(OBJ.options.common.box_size));
    end

    depth_bounded_cable_mask_rotated = ...
        log(depth_bounded_cable_mask_rotated) > OBJ.options.cable_mask.cable_thresh;

    if opts.process_frames
        depth_bounded_cable_mask_rotated = process_frame(depth_bounded_cable_mask_rotated, ...
            'open_reps', OBJ.options.cable_mask.open_reps, ...
            'open_size', OBJ.options.cable_mask.open_size, ...
            'dilate_reps', OBJ.options.cable_mask.dilate_reps, ...
            'dilate_size', OBJ.options.cable_mask.dilate_size);
    end

    if isnan(opts.missing_value)
        opts.missing_value = intmin(class(depth_bounded_rotated));
    end

    floor_pxs = depth_bounded_rotated < OBJ.options.common.height_floor;
    depth_bounded_rotated(~depth_bounded_cable_mask_rotated & ~floor_pxs) = opts.missing_value;
    depth_bounded_rotated(floor_pxs) = 0;

    if opts.process_frames
        depth_bounded_rotated = process_frame(depth_bounded_rotated, ...
            'med_filt_size', OBJ.options.common.med_filt_size, ...
            'med_filt_time', OBJ.options.common.med_filt_time, ...
            'hampel_span', OBJ.options.common.hampel_span, ...
            'hampel_sigma', OBJ.options.common.hampel_sigma);
    end

elseif ~opts.raw

    if isempty(opts.frame_idx)
        load(OBJ.files.orient{1}, 'depth_bounded_rotated', 'depth_bounded_mouse_mask_rotated');
    else
        m = matfile(OBJ.files.orient{1});
        depth_bounded_rotated = m.depth_bounded_rotated(:, :, opts.frame_idx);
        depth_bounded_mouse_mask_rotated = m.depth_bounded_mouse_mask_rotated(:, :, opts.frame_idx);
        clear m;
    end

    if opts.use_transform & OBJ.status.has_transform
        depth_bounded_rotated = ...
            imwarp(depth_bounded_rotated, OBJ.transform, 'OutputView', imref2d(OBJ.options.common.box_size));
        depth_bounded_moopts.use_mask_rotated = ...
            imwarp(depth_bounded_mouse_mask_rotated, OBJ.transform, 'OutputView', imref2d(OBJ.options.common.box_size));
    end

    if opts.use_mask
        depth_bounded_rotated = depth_bounded_rotated .* int16(depth_bounded_mouse_mask_rotated);
    end

    depth_bounded_rotated(depth_bounded_rotated < OBJ.options.common.height_floor) = 0;

    if opts.process_frames
        depth_bounded_rotated = process_frame(depth_bounded_rotated, ...
            'med_filt_size', OBJ.options.common.med_filt_size, ...
            'med_filt_time', OBJ.options.common.med_filt_time, ...
            'hampel_span', OBJ.options.common.hampel_span, ...
            'hampel_sigma', OBJ.options.common.hampel_sigma, ...
            'open_size', OBJ.options.common.open_size, ...
            'open_reps', OBJ.options.common.open_reps);
    end

    opts.missing_value = [];
else

    if isempty(opts.frame_idx)
        load(OBJ.files.orient{1}, 'depth_bounded_rotated');
    else
        m = matfile(OBJ.files.orient{1});
        depth_bounded_rotated = m.depth_bounded_rotated(:, :, opts.frame_idx);
        clear m;
    end

    if opts.use_transform & OBJ.status.has_transform
        depth_bounded_rotated = ...
            imwarp(depth_bounded_rotated, OBJ.transform, 'OutputView', imref2d(OBJ.options.common.box_size));
    end

    opts.missing_value = [];
    %depth_bounded_rotated(depth_bounded_rotated<OBJ.options.common.height_floor)=0;
end

BOUNDED_FRAMES = depth_bounded_rotated;

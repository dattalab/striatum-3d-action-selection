function CATDATA = load_oriented_frames_cat(OBJ, varargin)
%
%

opts = struct( ...
    'raw', false, ...
    'use_transform', false, ...
    'missing_value', nan, ...
    'process_frames', true, ...
    'use_mask', true, ...
    'max_frames', inf);

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

opts_cell = map_parameters(opts);

idx_counter = 0;
frame_counter = 0;

edge_size = OBJ(1).options.common.box_size(1);
tot_frames = 0;

for i = 1:length(OBJ)
    tot_frames = tot_frames + OBJ(i).metadata.nframes;
end

frame_idx = zeros(tot_frames, 2);
fprintf('%i total frames\n', tot_frames);

for i = 1:length(OBJ)
    nframes = OBJ(i).metadata.nframes;
    frame_idx(frame_counter + 1:frame_counter + nframes, 1) = 1:OBJ(i).metadata.nframes;
    frame_idx(frame_counter + 1:frame_counter + nframes, 2) = i;
    frame_counter = frame_counter + nframes;
end

if frame_counter > opts.max_frames
    fprintf('Will use %i frames (selected by random draw)\n', opts.max_frames);
    to_use = randsample(1:frame_counter, opts.max_frames);
    frame_idx = frame_idx(to_use, :);
end

frame_counter = size(frame_idx, 1);

% if we're over max frames, create a list of indices and files...

CATDATA = zeros(edge_size, edge_size, frame_counter, 'int16');

% assume we're looping over extract objects, need method to load in frames
% and apply mask

fprintf('Loading frames...\n');
upd = kinect_extract.proc_timer(frame_counter);

for i = 1:length(OBJ)

    tmp_frames = frame_idx(frame_idx(:, 2) == i, 1);
    nframes = numel(tmp_frames);
    depth_bounded_rotated = OBJ(i).load_oriented_frames(opts_cell{:});
    CATDATA(:, :, idx_counter + 1:idx_counter + nframes) = depth_bounded_rotated(:, :, tmp_frames);
    idx_counter = idx_counter + nframes;
    upd(idx_counter);

end

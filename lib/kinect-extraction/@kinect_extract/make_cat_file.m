function make_cat_file(OBJ, varargin)
%
%

opts = struct( ...
    'raw', false, ...
    'use_transform', false, ...
    'missing_value', nan, ...
    'process_frames', true, ...
    'use_mask', true);

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

% if we're over max frames, create a list of indices and files...
%
%

nframes = OBJ.get_frame_total;
fprintf('%i total frames\n', nframes);

[pathname, filename, ext] = fileparts(OBJ(1).files.cat_frames{1});

if ~exist(pathname, 'dir')
    mkdir(pathname);
end

MMAP = matfile(OBJ(1).files.cat_frames{1});
MMAP.Properties.Writable = true;
unrolled_size = prod(OBJ(1).options.common.box_size);
MMAP = matfile_init_var(MMAP, 'single', 'cat_frames', [unrolled_size nframes]);
MMAP = matfile_init_var(MMAP, 'uint32', 'frame_idx', [2 length(OBJ)]);
MMAP.uuid = cell(1, length(OBJ));
MMAP.copy_complete = false;

fprintf('Loading frames...\n');
upd = kinect_extract.proc_timer(nframes);
idx = 0;

for i = 1:length(OBJ)

    depth_bounded_rotated = OBJ(i).load_oriented_frames(opts_cell{:});
    tmp_frames = size(depth_bounded_rotated, 3);

    if isinteger(depth_bounded_rotated)
        missing_value = intmin(class(depth_bounded_rotated));
    elseif isfloat(depth_bounded_rotated)
        missing_value = nan;
    end

    depth_bounded_rotated = cast(depth_bounded_rotated, 'single');
    depth_bounded_rotated(depth_bounded_rotated == missing_value) = nan;

    MMAP.cat_frames(:, idx + 1:idx + tmp_frames) = reshape(depth_bounded_rotated, unrolled_size, tmp_frames);
    MMAP.frame_idx(1, i) = idx + 1;
    MMAP.frame_idx(2, i) = idx + tmp_frames;
    MMAP.uuid(1, i) = {OBJ(i).metadata.uuid};

    idx = idx + tmp_frames;
    clear depth_bounded_rotated;
    upd(idx);

end

MMAP.copy_complete = true;
OBJ.update_status;
clear MMAP;

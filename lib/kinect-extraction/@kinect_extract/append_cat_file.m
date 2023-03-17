function append_cat_file(OBJ, RAW, USE_TRANSFORM, MISSING_VALUE)
%
%

if nargin < 4 | isempty(MISSING_VALUE)
    MISSING_VALUE = nan;
end

if nargin < 3 | isempty(USE_TRANSFORM)
    USE_TRANSFORM = false;
end

if nargin < 2 | isempty(RAW)
    RAW = false;
end

% Appends the object to the corresponding cat file
%
%

if ~OBJ(1).files.cat_frames{2}
    fprintf('Not a valid cat frame file %s\n', OBJ(1).files.cat_frames{1});
    return;
end

MMAP = matfile(OBJ(1).files.cat_frames{1});
MMAP.Properties.Writable = true;
unrolled_size = prod(OBJ(1).options.common.box_size);

current_size = size(MMAP, 'uuid', 2);
current_frames = size(MMAP, 'cat_frames', 2);

nframes = OBJ.get_frame_total;

fprintf('Loading frames...\n');

idx = current_frames;
uuids = MMAP.uuid;

% make sure we're not adding anything redundant, or just strip out those objects

for i = 1:length(OBJ)

    if any(strcmp(OBJ(i).metadata.uuid, uuids))
        error('UUID %s already exists!', OBJ(i).metadata.uuid);
    end

end

MMAP.copy_complete = false;
upd = kinect_extract.proc_timer(nframes);

for i = 1:length(OBJ)

    depth_bounded_rotated = OBJ(i).load_oriented_frames('raw', RAW, ...
        'use_transform', USE_TRANSFORM, ...
        'missing_value', MISSING_VALUE);

    if isinteger(depth_bounded_rotated)
        missing_value = intmin(class(depth_bounded_rotated));
    end

    depth_bounded_rotated = cast(depth_bounded_rotated, 'single');
    depth_bounded_rotated(depth_bounded_rotated == missing_value) = nan;

    tmp_frames = size(depth_bounded_rotated, 3);

    MMAP.cat_frames(1:unrolled_size, idx + 1:idx + tmp_frames) = reshape(depth_bounded_rotated, unrolled_size, tmp_frames);
    MMAP.frame_idx(1, current_size + i) = idx + 1;
    MMAP.frame_idx(2, current_size + i) = idx + tmp_frames;
    MMAP.uuid(1, current_size + i) = {OBJ(i).metadata.uuid};
    idx = idx + tmp_frames;
    upd(idx - current_frames);

end

MMAP.copy_complete = true;
clear MMAP;

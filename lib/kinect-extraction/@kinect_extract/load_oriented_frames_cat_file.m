function FRAMES = load_oriented_frames_cat_file(OBJ, USE_SCRATCH)
%
%
%
%

if nargin < 2 | isempty(USE_SCRATCH)
    USE_SCRATCH = false;
end

if USE_SCRATCH
    mmap_filename = 'cat_frames_scratch';
else
    mmap_filename = 'cat_frames';
end

if OBJ.files.(mmap_filename){2}
    mmap = matfile(OBJ.files.(mmap_filename){1});
else
    error('File not present (did you run get_pcs first?)')
end

uuids = mmap.uuid;
uuid_idx = find(strcmp(OBJ.metadata.uuid, uuids));

if ~any(uuid_idx)
    error('Could not find uuid %s', OBJ.metadata.uuid);
elseif length(uuid_idx) > 1
    error('More than one uuid match, cat file is likely to be corrupted...');
end

mmap_nframes = (mmap.frame_idx(2, uuid_idx) - mmap.frame_idx(1, uuid_idx)) + 1;

if OBJ.metadata.nframes == mmap_nframes
    FRAMES = mmap.cat_frames(:, mmap.frame_idx(1, uuid_idx):mmap.frame_idx(2, uuid_idx));
else
    error('Frame number does not match for uuid %s', OBJ.metadata.uuid)
end

function [STATUS, MAP, TO_ADD, FRAME_MATCH] = check_cat_file(OBJ, USE_SCRATCH)
% makes sure the cat frames file is kosher
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

STATUS = true;
FRAME_MATCH = true(1, length(OBJ));
MAP = nan(1, length(OBJ));
TO_ADD = {};

if ~OBJ(1).files.(mmap_filename){2}
    fprintf('Check that the cat file is present, not found at %s\n', OBJ(1).files.(mmap_filename){1});
    STATUS = false;
    return;
end

mmap = matfile(OBJ(1).files.(mmap_filename){1});
mmap_nframes = diff(mmap.frame_idx) + 1;
uuids = mmap.uuid;

for i = 1:length(OBJ)

    % make sure we can find the uuid somewhere

    uuid_idx = strcmp(uuids, OBJ(i).metadata.uuid);
    obj_frames = OBJ(i).metadata.nframes;

    if ~any(uuid_idx)
        STATUS = false;
        TO_ADD{end + 1} = OBJ(i).metadata.uuid;
        FRAME_MATCH(i) = false;
    elseif sum(uuid_idx) > 1
        fprintf('File is corrupted, nuke the site from orbit...\n');
        return;
    else
        MAP(i) = find(uuid_idx);

        if ~obj_frames == mmap_nframes(uuid_idx)
            FRAME_MATCH(i) = false;
            STATUS = false;
        end

    end

end

clear mmap;

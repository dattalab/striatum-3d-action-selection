function load_use_frames(OBJ, FORCE)
%
%

if nargin < 2 | isempty(FORCE)
    FORCE = false;
end

for i = 1:length(OBJ)

    if OBJ(i).files.use_frames{2}
        load(OBJ(i).files.use_frames{1}, 'use_frames');
        OBJ(i).metadata.use_frames = use_frames;
    elseif OBJ(i).files.frame_idx{2}
        load(OBJ(i).files.frame_idx{1}, 'frame_idx');
        OBJ(i).metadata.use_frames = frame_idx;
    end

end

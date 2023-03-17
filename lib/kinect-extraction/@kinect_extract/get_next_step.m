function [NEXT_STEP, NEXT_IDX, STEPS] = get_next_step(OBJ)
% return the next preprocessing step (empty if complete)

[STEPS, flags] = OBJ.get_steps;
NEXT_STEP = [];

% check all flags
flag_status = nan(size(flags));

for i = 1:numel(flags)
    flag_status(i) = OBJ.status.(flags{i});
end

% if the extract file is here, we're obligated to check for everything
% otherwise, assume we have everything from the track_stats forward

track_idx = strcmp(flags, 'track_stats');
track_idx(find(track_idx):end) = true;

if OBJ.files.raw_data{2}
    NEXT_IDX = min(find(flag_status == 0));
else
    NEXT_IDX = min(find(flag_status == 0 & track_idx));
end

if isempty(NEXT_IDX) | (NEXT_IDX > numel(flags))
    NEXT_IDX = nan;
end

if ~isnan(NEXT_IDX)
    NEXT_STEP = STEPS{NEXT_IDX};
end

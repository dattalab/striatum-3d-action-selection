function sort_states_by_usage(OBJ, FORCE, IDX)
%
%
%
%

if nargin < 3
    IDX = [];
end

if nargin < 2
    FORCE = false;
end

% sort the states yo

if isempty(IDX)
    usage = OBJ.get_syllable_usage;
else
    usage = OBJ(IDX).get_syllable_usage;
end

[~, idx] = sort(usage, 'descend');
state_list = [];

for i = 1:length(OBJ)

    if ~isempty(OBJ(i).labels)
        state_list = OBJ(i).states;
        break;
    end

end

for i = 1:length(OBJ)

    % make a copy of the sequence, replace in the copy, then copy back to object

    if isempty(OBJ(i).states)
        continue;
    end

    if OBJ(i).sorted & ~FORCE
        fprintf('%i already sorted\n', i);
        continue;
    end

    OBJ(i).original_states = state_list(idx);

    label_copy = OBJ(i).labels;

    for j = 1:length(idx)
        label_copy(OBJ(i).labels == state_list(idx(j))) = j;
    end

    OBJ(i).labels = label_copy;
    OBJ(i).state_idx = OBJ(i).state_idx(idx);
    OBJ(i).states = 1:length(idx);
    OBJ(i).state_starts = OBJ(i).state_starts(idx);
    OBJ(i).state_stops = OBJ(i).state_stops(idx);
    OBJ(i).state_durations = OBJ(i).state_durations(idx);
    OBJ(i).sorted = true;

end

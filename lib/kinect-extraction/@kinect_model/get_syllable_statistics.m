function get_syllable_statistics(OBJ)
%
%
%
%
%
%

%

% get all of the unique states that are used

all_labels = cellfun(@(x) x(:), {OBJ(:).labels}, 'UniformOutput', false);
states = unique(cat(1, all_labels{:}));
states(states < 0) = [];
states = states(:)';

len = cellfun(@length, {OBJ(:).labels});

% retrieve the basic syllable stats
upd = kinect_extract.proc_timer(sum(len));
counter = 0;

for i = 1:length(OBJ)

    if isempty(OBJ(i).labels)
        continue;
    end

    OBJ(i).states = states;
    labels = OBJ(i).labels;
    labels = [labels; -1];

    OBJ(i).state_idx = cell(size(OBJ(i).states));
    OBJ(i).state_starts = cell(size(OBJ(i).states));
    OBJ(i).state_stops = cell(size(OBJ(i).states));
    OBJ(i).state_durations = cell(size(OBJ(i).states));

    if labels >= 0
        labels = [-1; labels];
        offset = 1;
    else
        offset = 0;
    end

    for j = 1:length(states)

        % get the duration distribution of each state

        hit_vec = labels == states(j);
        idx = [1:length(hit_vec) - 1];

        OBJ(i).state_idx{j} = find(hit_vec) - offset;
        OBJ(i).state_starts{j} = find(~hit_vec(idx) & hit_vec(idx + 1)) + 1 - offset;
        OBJ(i).state_stops{j} = find(hit_vec(idx) & ~hit_vec(idx + 1)) - offset;
        OBJ(i).state_durations{j} = OBJ(i).state_stops{j} - OBJ(i).state_starts{j};

    end

    counter = counter + len(i);
    upd(counter);

end

upd(inf);

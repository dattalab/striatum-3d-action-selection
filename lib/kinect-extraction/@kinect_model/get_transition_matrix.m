function TRANS = get_transition_matrix(OBJ, USE_FRAMES)
%
%
%
%

if nargin < 2
    USE_FRAMES = [1 inf];
end

% reshape into two row matrix, count up matches

state_ids = OBJ(1).states;
%all_pairs=nchoosek([1:length(state_ids)],2);
[all_pairs_x all_pairs_y] = meshgrid(state_ids, state_ids);
all_pairs = [all_pairs_x(:) all_pairs_y(:)];
all_pairs(all_pairs(:, 1) == all_pairs(:, 2), :) = [];

upd = kinect_extract.proc_timer(length(OBJ) * size(all_pairs, 1), 'frequency', 1000);
counter = 0;

for i = 1:length(OBJ)

    OBJ(i).transition_matrix = zeros(length(state_ids), length(state_ids), 'uint16');

    nframes = length(OBJ(i).labels);
    use_frames = USE_FRAMES;

    if use_frames(2) > nframes
        use_frames(2) = nframes;
    end

    use_frames = use_frames(1):use_frames(2);

    seq = OBJ(i).labels(use_frames);
    seq = seq(find(diff(seq)));

    for j = 1:size(all_pairs, 1)
        %hits=all(ismember(use_labels,all_pairs(j,:)'));
        hits = length(findstr(seq(:)', all_pairs(j, :)));
        OBJ(i).transition_matrix(all_pairs(j, 1), all_pairs(j, 2)) = hits;
        counter = counter + 1;
        upd(counter);
    end

    TRANS = OBJ(i).transition_matrix;

end

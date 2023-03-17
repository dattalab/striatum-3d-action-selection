function make_montage_movies(OBJ, IDX, EXT)
% given state labels, make some movies
%
%
%

if nargin < 3
    EXT = '';
end

if nargin < 2 | isempty(IDX)
    % do something here
end

if ~exist(OBJ(1).options.common.analysis_dir, 'dir')
    mkdir(OBJ(1).options.common.analysis_dir);
end

% TODO: index into the cat_frames scratch file

prior_frames = 30;
post_frames = 30;
max_examples = 40;
box_size = OBJ(1).options.common.box_size;

ncols = 5;

% sort by usage, take a specific number

% get the durations, take n frames prior to the start and n frames after

% uniform random sampling of each syllable...

if isfield(OBJ(1).behavior_model.metadata, 'uuid')
    save_dir = fullfile(OBJ(1).options.common.analysis_dir, ...
        sprintf('model-%s-%05i_crowd_movies', ...
        OBJ(1).behavior_model.metadata.uuid, ...
        OBJ(1).behavior_model.metadata.model_idx));
else
    save_dir = fullfile(OBJ(1).options.common.analysis_dir);
end

if ~isempty(EXT)
    save_dir = sprintf('%s%s', save_dir, EXT);
end

if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

idx = IDX;

for i = 1:length(idx)

    % get the number of hits

    % remove any that don't have enough prior/post frames
    curr_syllable = OBJ(1).behavior_model.states(idx(i));
    original_idx = OBJ(1).behavior_model.original_states(idx(i));

    start_examples = [];
    stop_examples = [];
    nframes = zeros(length(OBJ), 1);

    for j = 1:length(OBJ)

        if isempty(OBJ(j).behavior_model.labels)
            continue;
        end

        tmp = OBJ(j).behavior_model.state_starts{idx(i)};
        start_examples = [start_examples; [tmp(:) ones(size(tmp(:))) * j]];

        tmp = OBJ(j).behavior_model.state_stops{idx(i)};
        stop_examples = [stop_examples; [tmp(:) ones(size(tmp(:))) * j]];
        nframes(j) = OBJ(j).metadata.nframes;
    end

    % shift start by prior frames

    start_examples(:, 1) = start_examples(:, 1) - prior_frames;
    stop_examples(:, 1) = stop_examples(:, 1) + post_frames;

    % get the new durations

    dur_examples = (stop_examples(:, 1) - start_examples(:, 1)) + 1;
    dur_actual = dur_examples - (prior_frames + post_frames);
    to_del1 = start_examples(:, 1) < 1;
    to_del2 = stop_examples(:, 1) > nframes(stop_examples(:, 2));
    to_del = (to_del1 | to_del2);

    start_examples(to_del, :) = [];
    dur_examples(to_del) = [];
    dur_actual(to_del) = [];

    if isempty(start_examples)
        continue;
    end

    nhits = size(start_examples, 1);
    nuse = min(nhits, max_examples);

    use_idx = randperm(nhits);
    use_idx = use_idx(1:nuse);

    % include marker for syllable on in each sub-frame?

    start_examples = start_examples(use_idx, :);
    dur_examples = dur_examples(use_idx);
    dur_actual = dur_actual(use_idx);

    max_dur = max(dur_examples);
    extract_examples = start_examples(:, 1) + max_dur;

    to_del = extract_examples > nframes(start_examples(:, 2));

    start_examples(to_del, :) = [];
    dur_examples(to_del) = [];
    dur_actual(to_del) = [];

    max_dur = max(dur_examples);
    extract_examples = start_examples(:, 1) + max_dur;

    % load in movies as needed

    files_to_use = unique(start_examples(:, 2));
    nrows = ceil(nuse / ncols);

    % pre-allocate our matrix

    cur_row = 1;
    cur_col = 1;

    mov_matrix = zeros(nrows * box_size(1), ncols * box_size(2), ...
        max_dur + 1, 'int16');
    marker_coords = cell(1, max_dur + 1);

    for j = 1:length(files_to_use)

        % TODO: add option to use SVD reconstruction

        depth_bounded_rotated = OBJ(files_to_use(j)).load_oriented_frames('raw', true);
        new_idx = start_examples(:, 2) == files_to_use(j);

        syllable_idx = int16(OBJ(files_to_use(j)).behavior_model.labels == curr_syllable);

        start_cur = start_examples(new_idx, 1);
        extract_cur = extract_examples(new_idx);

        write_examples = size(start_cur, 1);

        for k = 1:write_examples

            % grab the indices

            row_cnt = (cur_row - 1) * box_size(1);
            col_cnt = (cur_col - 1) * box_size(2);

            bot = row_cnt + 1;
            top = row_cnt + box_size(1);

            left = col_cnt + 1;
            right = col_cnt + box_size(2);

            mov_matrix(bot:top, left:right, :) = ...
                depth_bounded_rotated(:, :, start_cur(k):extract_cur(k));

            marker_idx = find(syllable_idx(start_cur(k):extract_cur(k)));

            for l = 1:length(marker_idx)
                x_coords = left:left + 10;
                y_coords = bot:bot + 10;
                marker_coords{marker_idx(l)} = ...
                    [marker_coords{marker_idx(l)}; x_coords(:) y_coords(:)];
            end

            cur_col = cur_col + 1;

            if cur_col > ncols
                cur_col = 1;
                cur_row = cur_row + 1;
            end

        end

    end

    % may want to dispatch for asynchronous processing, but may not be necessary
    % unless we have lots of syllables

    kinect_extract.animate_direct(mov_matrix, ...
        'marker_coords', marker_coords, 'clim', 'auto', ...
        'auto_per', [.5 100], 'cmap', jet(256), ...
        'filename', fullfile(save_dir, ...
        sprintf('syllable_%i_%i', i, curr_syllable)));

    % across the cell array, find

end

function make_crowd_movies(OBJ, IDX, EXT)
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
im_size = OBJ(1).metadata.extract.DepthResolution;
box_size = OBJ(1).options.common.box_size;

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

    % pre-allocate our matrix

    marker_coords = cell(1, max_dur + 1);
    mov_matrix = zeros(im_size(2), im_size(1), max_dur + 1, 'int16');

    for j = 1:length(files_to_use)

        depth_bounded_rotated = OBJ(files_to_use(j)).load_oriented_frames('raw', true);
        centroid = OBJ(files_to_use(j)).tracking.centroid;
        orientation = OBJ(files_to_use(j)).tracking.orientation;
        new_idx = start_examples(:, 2) == files_to_use(j);

        syllable_idx = int16(OBJ(files_to_use(j)).behavior_model.labels == curr_syllable);

        start_cur = start_examples(new_idx, 1);
        extract_cur = extract_examples(new_idx);

        write_examples = size(start_cur, 1);

        for k = 1:write_examples

            % grab the indices

            use_frames = int16(depth_bounded_rotated(:, :, start_cur(k):extract_cur(k)));
            use_frames(use_frames < 15) = 0;
            write_angle = orientation(start_cur(k):extract_cur(k));
            write_centroid = round(centroid(start_cur(k):extract_cur(k), :));
            marker_idx = find(syllable_idx(start_cur(k):extract_cur(k)));

            for l = 1:size(use_frames, 3)

                new_frame = zeros(im_size(2), im_size(1), 'int16');
                insert_mouse = imrotate(use_frames(:, :, l), write_angle(l), 'bilinear', 'crop');
                coords_x = (write_centroid(l, 1) - (box_size(2) / 2 - 1)):(write_centroid(l, 1) + box_size(2) / 2);
                coords_y = (write_centroid(l, 2) - (box_size(1) / 2 - 1)):(write_centroid(l, 2) + box_size(1) / 2);

                new_frame(coords_y, coords_x) = insert_mouse;
                ref = mov_matrix(:, :, l);

                % average non-zero pxs

                mov_nz = ref > 0;
                new_nz = new_frame > 0;

                % if both are non-zero, average, if new frame is non-zero and not
                % the ref, then don't average

                ref(mov_nz & new_nz) = .5 * ref(mov_nz & new_nz) + .5 * new_frame(mov_nz & new_nz);
                ref(~mov_nz & new_nz) = new_frame(~mov_nz & new_nz);
                mov_matrix(:, :, l) = ref;

                %mov_matrix(:,:,l)=imlincomb(.5,double(new_frame),.5,double(mov_matrix(:,:,l)));
            end

            for l = 1:length(marker_idx)
                x_coords = write_centroid(marker_idx(l), 1);
                x_coords = x_coords - 1:x_coords + 1;
                y_coords = write_centroid(marker_idx(l), 2);
                y_coords = y_coords - 1:y_coords + 1;
                [x_coords, y_coords] = meshgrid(x_coords, y_coords);
                marker_coords{marker_idx(l)} = ...
                    [marker_coords{marker_idx(l)}; x_coords(:) y_coords(:)];
            end

        end

    end

    % may want to dispatch for asynchronous processing, but may not be necessary
    % unless we have lots of syllables

    kinect_extract.animate_direct(mov_matrix, ...
        'marker_coords', marker_coords, 'clim', [5 80], ...
        'cmap', jet(256), ...
        'filename', fullfile(save_dir, ...
        sprintf('syllable_%i_%i', i, curr_syllable)));

    % across the cell array, find

end

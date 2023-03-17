function make_example_movies(OBJ, BEH, NFRAMES, NEXAMPLES, MIN_DUR)
%
%
%
%

if nargin < 5 | isempty(MIN_DUR)
    MIN_DUR = 5;
end

if nargin < 4 | isempty(NEXAMPLES)
    NEXAMPLES = 5;
end

if nargin < 3 | isempty(NFRAMES)
    NFRAMES = 60;
end

if nargin < 2
    error('Need at last one syllable...');
end

% get a list of all starts from all OBJects, randomly select which ones to use

beh_obj = OBJ.get_behavior_object;

for i = 1:length(BEH)

    if isfield(OBJ(1).behavior_model.metadata, 'uuid')
        save_dir = fullfile(OBJ(1).options.common.analysis_dir, ...
            sprintf('model-%i_%s', OBJ(1).behavior_model.metadata.model_idx, OBJ(1).behavior_model.metadata.uuid), ...
            sprintf('syllable_%i', BEH(i)));
    else
        save_dir = fullfile(OBJ(1).options.common.analysis_dir, sprintf('syllable_%i', BEH(i)));
    end

    if ~exist(save_dir, 'dir')
        mkdir(save_dir);
    end

    use_list = [];

    for j = 1:length(OBJ)
        matches = beh_obj(j).state_starts{BEH(i)}(beh_obj(j).state_durations{BEH(i)} > 5);
        matches(matches <= NFRAMES) = [];
        matches(matches >= (length(beh_obj(j).labels) - NFRAMES)) = [];
        use_list = [use_list; j * ones(size(matches(:))) matches(:)];
    end

    total_examples = size(use_list, 1);

    if NEXAMPLES < total_examples
        use_list = use_list(randsample(1:total_examples, NEXAMPLES), :);
    end

    if total_examples < 1
        warning('No examples to plot for syllable %i', BEH(i))
        continue;
    end

    idx = unique(use_list(:, 1));
    counter = 1;

    for j = 1:length(idx)

        tmp_examples = find(use_list(:, 1) == idx(j));
        use_obj = idx(j);
        use_frames = OBJ(use_obj).load_oriented_frames('raw', true);
        syll_idx = beh_obj(use_obj).labels == BEH(i);

        for k = 1:length(tmp_examples)

            hit_onset = use_list(tmp_examples(k), 2);
            use_idx = syll_idx(hit_onset - NFRAMES:hit_onset + NFRAMES);
            mov_frames = use_frames(:, :, hit_onset - NFRAMES:hit_onset + NFRAMES);
            marker_coords = cell(1, size(mov_frames, 3));

            for l = 1:length(marker_coords)

                if use_idx(l)
                    [xcoords, ycoords] = meshgrid(1:10, 1:10);
                    marker_coords{l} = [xcoords(:) ycoords(:)];
                end

            end

            kinect_extract.animate_direct(mov_frames, ...
                'cmap', jet(256), 'marker_coords', marker_coords, 'filename', ...
                fullfile(save_dir, sprintf('syllable_%i_example%i', BEH(i), counter)), ...
                'clim', [0 80]);
            counter = counter + 1;
        end

    end

end

function [TRAINING_X, TRAINING_Y, TRAINING_METADATA] = get_decoder_variables(OBJ, POPULATION, USE_OBJ)
% function to gather data for decoding NARF
%
%
%

TRAINING_METADATA = struct();

if nargin < 3
    USE_OBJ = 1;
end

if nargin < 2 | isempty(POPULATION)
    POPULATION = false;
end

switch lower(OBJ.data_type(1))

    case 'p'

    case 'i'

        if POPULATION

            if OBJ.options.decode_cluster_neurons

                all_cadata = OBJ.normalize_trace([OBJ.imaging(USE_OBJ).traces(:).raw]);
                all_cadata(isnan(all_cadata)) = 0;
                [coef score] = pca(all_cadata');
                cluster_idx = kmeans(score(:, 1:3), 5, 'replicates', 20);
                nclusters = length(unique(cluster_idx));

            end

            if OBJ.options.decode_cluster_behavior

                use_dist = sqrt(abs(OBJ.distance.inter.kl));
                cut = 40;
                beh_cluster_idx = kmeans(use_dist(1:cut, 1:cut), 10, 'replicates', 20);

            end

            tmp = OBJ.stats.model_starts.imaging(:, USE_OBJ);

            [nsyllables, nsessions] = size(tmp);

            max_lag = OBJ.options.max_lag;

            if ~isempty(OBJ.options.decode_window)
                window_samples = round(OBJ.options.decode_window * OBJ.options.fs);
                window_vec = [-window_samples(1):window_samples(2)];
            end

            nexamples = zeros(nsyllables, nsessions);

            for i = 1:nsyllables

                for j = 1:nsessions
                    nexamples(i, j) = size(tmp(i, j).wins, 3);
                end

            end

            if ~isempty(OBJ.options.decode_binfun) & isa(OBJ.options.decode_binfun, 'function_handle') & OBJ.options.decode_compress
                nsamples = 1;
                compress = true;
            elseif ~isempty(window_samples)
                nsamples = length(window_vec);
                compress = false;
            else
                error('Window options are awry');
            end

            if ~OBJ.options.decode_cluster_neurons
                total_rois = 0;

                for i = 1:size(tmp, 2)
                    total_rois = total_rois + size(tmp(1, i).wins, 2);
                end

            else
                total_rois = nclusters;
            end

            nrows = nsamples * total_rois;
            total_examples = sum(nexamples(:));

            TRAINING_X = nan(nrows, total_examples);
            TRAINING_Y = nan(1, total_examples);

            counter = 1;

            for i = 1:nsyllables

                for j = 1:nsessions

                    % stick together the ROIs using all of our desired options

                    dims = ndims(tmp(i, j).wins);

                    if OBJ.options.decode_normalize
                        tmp(i, j).wins = phanalysis.nanzscore(tmp(i, j).wins);
                    end

                    durs = tmp(i, j).durations;

                    if compress & dims == 3

                        if ~isempty(OBJ.options.decode_window)
                            use_data = squeeze(OBJ.options.decode_binfun(tmp(i, j).wins(max_lag - window_samples(1):max_lag + window_samples(2), :, :)));
                        else
                            use_data = nan(size(tmp(i, j).wins, 2), size(tmp(i, j).wins, 3));

                            for k = 1:size(tmp(i, j).wins, 3)
                                use_data(:, k) = squeeze(OBJ.options.decode_binfun(tmp(i, j).wins(max_lag:max_lag + durs(k), :, k)));
                            end

                        end

                    elseif compress & dims == 2

                        if ~isempty(OBJ.options.decode_window)
                            use_data = OBJ.options.decode_binfun(tmp(i, j).wins(max_lag - window_samples(1):max_lag + window_samples(2), :, :))';
                        else
                            use_data = nan(size(tmp(i, j).wins, 2), size(tmp(i, j).wins, 3));

                            for k = 1:size(tmp(i, j).wins, 3)
                                use_data(:, k) = (OBJ.options.decode_binfun(tmp(i, j).wins(max_lag:max_lag + durs(k), :, k)));
                            end

                        end

                    else
                        use_data = tmp(i, j).wins(max_lag - window_samples(1):max_lag + window_samples(2), :, :);
                        use_data = reshape(use_data, size(use_data, 1) * size(use_data, 2), []);
                    end

                    if OBJ.options.decode_cluster_neurons & compress

                        tmp2 = use_data;
                        use_data = nan(nclusters, size(use_data, 2));

                        for k = 1:nclusters

                            if sum(cluster_idx == k) > 1
                                use_data(k, :) = nanmean(tmp2(cluster_idx == k, :));
                            else
                                use_data(k, :) = tmp2(cluster_idx == k, :);
                            end

                        end

                    end

                    % allow for averaging over small blocks...

                    use_examples = size(use_data, 2);

                    if ~isempty(OBJ.options.decode_trial_block)

                        bin_edges = unique([1 [1:OBJ.options.decode_trial_block:use_examples] use_examples]);
                        idx = [1:use_examples];
                        [~, ~, bin_idx] = histcounts(idx, bin_edges);
                        new_use_data = nan(size(use_data, 1), length(bin_edges) - 1);

                        for k = 1:size(use_data, 1)
                            new_use_data(k, :) = accumarray(bin_idx(:), use_data(k, :), [], @max);
                        end

                        use_data = new_use_data;

                    end

                    use_examples = size(use_data, 2);

                    TRAINING_X(:, counter + 1:counter + use_examples) = use_data;

                    if OBJ.options.decode_cluster_behavior
                        TRAINING_Y(counter + 1:counter + use_examples) = beh_cluster_idx(i);
                    else
                        TRAINING_Y(counter + 1:counter + use_examples) = i;
                    end

                    counter = counter + use_examples;

                end

            end

        else

        end

        TRAINING_X(:, counter:end) = [];
        TRAINING_Y(:, counter:end) = [];

    otherwise
        error('Did not understand data type, use either (i)maging or (p)hotometry')
end

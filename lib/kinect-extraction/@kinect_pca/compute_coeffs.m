function compute_coeffs(OBJ, FEATURES, varargin)
%%%%

% initialize the missing values (could be smarter here, may not matter)

[nfeatures, nframes] = size(FEATURES);

if OBJ.missing_data

    missing_value = intmin(class(FEATURES));
    missing_idx = FEATURES == missing_value;

    % assign mean value to each missing idx

    fprintf('Initializing missing values...\n');
    upd = kinect_extract.proc_timer(nframes, 'frequency', 1e2);

    for j = 1:nframes
        tmp = FEATURES(:, j);
        %FEATURES(missing_idx(:,j),j)=int16(mean(tmp(tmp>0)));
        FEATURES(missing_idx(:, j), j) = 0;
        upd(j);
    end

    if OBJ.options.iters_coeffs < 2
        clear missing_idx;
    end

else
    OBJ.options.iters_coeffs = 1;
end

% memory map everything, clear out any indexing unless totally necessary
% take SVD, reconstruct, fill in missing values, repeat

omega = [];
l2_error = 1e6;
fprintf('Computing PCs...\n');
upd = kinect_extract.proc_timer(OBJ.options.iters_coeffs);

for i = 1:OBJ.options.iters_coeffs

    % add as an option whether to use the power method or standard rand svd
    % unclear what we need ATM

    mu = int16(mean(FEATURES));

    % make sure data is centered

    FEATURES = bsxfun(@minus, FEATURES, mu);

    switch lower(OBJ.options.method(1))
        case 'p'
            [OBJ.coeffs OBJ.details.S OBJ.details.V omega] = randsvd_power(FEATURES, OBJ.options.randk, OBJ.options.randq, omega);
        case 'h'
            [OBJ.coeffs OBJ.details.S OBJ.details.V omega] = randsvd_halko(FEATURES, OBJ.options.randk, omega);
        case 'f'
            %fprintf('Full SVD\n');
            [OBJ.coeffs OBJ.details.S OBJ.details.V] = svd(FEATURES, 'econ');
        case 's'
            %fprintf('Parallel PCA %i of %i\n',i,OBJ.options.iters_coeffs);
            [OBJ.coeffs OBJ.details.latent OBJ.details.explained OBJ.details.cov_mat] = parallel_pca(FEATURES, ...
                'chunk_size', OBJ.frame_stride);
    end

    if OBJ.options.iters_coeffs > 1 & i < OBJ.options.iters_coeffs & OBJ.missing_data

        % reconstruct frame by frame

        %fprintf('Reconstructing data...\n');

        for j = 1:nframes
            reconstruction = ...
                single(FEATURES(:, j)') * OBJ.coeffs(:, 1:OBJ.options.cut_coeffs) * OBJ.coeffs(:, 1:OBJ.options.cut_coeffs)';
            reconstruction = int16(reconstruction) + mu(j);
            reconstruction(reconstruction < 5) = 0;
            FEATURES(missing_idx(:, j), j) = reconstruction(missing_idx(:, j));
            FEATURES(reconstruction == 0, j) = 0;
        end

    end

    if strcmp(lower(OBJ.options.stopping(1)), 'e')

        %fprintf('Computing reconstruction error...\n');
        old_l2_error = l2_error;
        reconstruction = ...
            (single(FEATURES(:, 1:OBJ.options.max_frames_norm)') ...
            * OBJ.coeffs(:, 1:OBJ.options.cut_coeffs) * OBJ.coeffs(:, 1:OBJ.options.cut_coeffs)')';
        reconstruction = bsxfun(@plus, int16(reconstruction), mu(1:OBJ.options.max_frames_norm));
        use_missing_idx = find(~missing_idx(:, 1:OBJ.options.max_frames_norm));
        l2_error = norm(single(reconstruction(use_missing_idx)) - single(FEATURES(use_missing_idx)));
        error_diff = (old_l2_error - l2_error) / old_l2_error;

        if error_diff > 0 & error_diff < OBJ.options.epsilon
            break;
        end

    end

    upd(i);

end

OBJ.update_status;

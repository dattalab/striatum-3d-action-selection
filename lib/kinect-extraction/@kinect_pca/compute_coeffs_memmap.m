function compute_coeffs_memmap(OBJ, FEATURES, varargin)
%%%%

mem_var = 'cat_frames';

% initialize the missing values (could be smarter here, may not matter)

if isa(FEATURES, 'matlab.io.MatFile')
    [nfeatures, nframes] = size(FEATURES, mem_var);
    FEATURES.Properties.Writable = true;
else
    error('Features must be an object returned by matfile...');
end

% steps will be the same errwhere

fprintf('Will load %i frames into memory at a time\n', OBJ.frame_stride);

steps = 0:OBJ.frame_stride:nframes;
steps = unique([steps nframes]);
nsteps = length(steps);

data_class = class(FEATURES.(mem_var)(:, 1));

if isinteger(FEATURES.(mem_var)(:, 1))
    data_type = 'int;'
    missing_value = intmin(data_class);
elseif isfloat(FEATURES.(mem_var)(:, 1))
    data_type = 'float';
else
    error('Did not understand data type....');
end

missing_idx = false(nfeatures, nframes);

fprintf('Getting missing indices...\n');

upd = kinect_extract.proc_timer(nsteps - 1);

for i = 1:nsteps - 1
    left_edge = steps(i);
    right_edge = steps(i + 1);

    if strcmp(data_type, 'int')
        missing_idx(:, left_edge + 1:right_edge) = ...
            FEATURES.(mem_var)(:, left_edge + 1:right_edge) == missing_value;
    else
        missing_idx(:, left_edge + 1:right_edge) = ...
            isnan(FEATURES.(mem_var)(:, left_edge + 1:right_edge));
    end

    upd(i);
end

% assign mean value to each missing idx

fprintf('Initializing missing values...\n');

mu = zeros(nfeatures, 1);
mu_den = zeros(nfeatures, 1);

% haha the idiot's running mean, no one can stop me!

for i = 1:nsteps - 1
    left_edge = steps(i);
    right_edge = steps(i + 1);
    tmp = single(FEATURES.(mem_var)(:, left_edge + 1:right_edge));
    tmp_missing = missing_idx(:, left_edge + 1:right_edge);
    tmp(tmp_missing) = nan;
    mu = mu + nansum(tmp, 2);
    mu_den = mu_den + single(sum(~tmp_missing, 2));
end

mu = cast(mu ./ mu_den, data_class);
upd = kinect_extract.proc_timer(nsteps - 1);

for i = 1:nsteps - 1

    left_edge = steps(i);
    right_edge = steps(i + 1);

    tmp = FEATURES.(mem_var)(:, left_edge + 1:right_edge);
    tmp_missing = missing_idx(:, left_edge + 1:right_edge);

    % yeah this is the memory-inefficient way, for now, we can use smart indexing if it proves useful
    % could just use sub2ind

    tmp_mu = repmat(mu, [1 size(tmp, 2)]);
    tmp(tmp_missing) = tmp_mu(tmp_missing);

    FEATURES.(mem_var)(:, left_edge + 1:right_edge) = tmp;
    upd(i);

end

% memory map everything, clear out any indexing unless totally necessary
% take SVD, reconstruct, fill in missing values, repeat

OBJ.details.l2_error = nan(1, OBJ.options.max_iters);
fprintf('Computing PCs...\n');

if OBJ.options.use_fft
    fprintf('Using abs(fft), setting max_iters to 1...\n');
    max_iters = 1;
else
    max_iters = OBJ.options.max_iters;
end

upd = kinect_extract.proc_timer(OBJ.options.max_iters);
terminate_condition = false;
i = 1;

while i <= max_iters & ~terminate_condition

    mu = zeros(nfeatures, 1);

    % haha the idiot's running mean, no one can stop me!

    for j = 1:nsteps - 1
        left_edge = steps(j);
        right_edge = steps(j + 1);
        tmp = FEATURES.(mem_var)(:, left_edge + 1:right_edge);
        mu = mu + sum(tmp, 2);
    end

    mu = cast(mu ./ nframes, data_class);

    for j = 1:nsteps - 1
        left_edge = steps(j);
        right_edge = steps(j + 1);
        tmp = FEATURES.(mem_var)(:, left_edge + 1:right_edge);
        tmp = bsxfun(@minus, tmp, mu);
        FEATURES.(mem_var)(:, left_edge + 1:right_edge) = tmp;
    end

    OBJ.details.mu = mu;

    % I'm only allowing parallel pca for memmaps, everything else is too complicated!

    [OBJ.coeffs OBJ.details.latent OBJ.details.explained OBJ.details.cov_mat] = ...
        kinect_pca.parallel_pca(FEATURES, 'chunk_size', OBJ.frame_stride, 'use_fft', OBJ.options.use_fft);

    % if max iterations only set to 1 we're not filling in...

    if max_iters == 1
        break;
    end

    l2_error = 0;

    for j = 1:nsteps - 1

        left_edge = steps(j);
        right_edge = steps(j + 1);

        tmp = FEATURES.(mem_var)(:, left_edge + 1:right_edge);
        tmp_missing = missing_idx(:, left_edge + 1:right_edge);

        % we're expressing ourselves awkwardly here, re-arrange!

        reconstruction = (single(tmp') * OBJ.coeffs(:, 1:OBJ.options.cut_recon) * OBJ.coeffs(:, 1:OBJ.options.cut_recon)')';
        l2_error = l2_error + norm(tmp(~tmp_missing) - reconstruction(~tmp_missing));

        % for reconstruction we'll need to put the mean back in

        reconstruction = bsxfun(@plus, reconstruction, mu);
        tmp = bsxfun(@plus, tmp, mu);

        % reconstruction(reconstruction<5)=0;
        % recon_zed=reconstruction==0;

        tmp(tmp_missing) = reconstruction(tmp_missing);
        % tmp(recon_zed)=0;

        % copy re-meaned data back!

        FEATURES.(mem_var)(:, left_edge + 1:right_edge) = tmp;

    end

    OBJ.details.l2_error(i) = l2_error;

    if i > 1
        error_diff = (OBJ.details.l2_error(i - 1) - OBJ.details.l2_error(i)) / OBJ.details.l2_error(i - 1);
        terminate_condition = abs(error_diff) < OBJ.options.epsilon;
    end

    i = i + 1;
    upd(i);

end

fprintf('\n');
OBJ.update_status;

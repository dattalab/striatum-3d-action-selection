function compute_interbehavior_distance(OBJ)
%
%
%
%

%use_syllables=length(unique(OBJ.behavior(1).states));
use_syllables = OBJ.options.syllable_cutoff;
OBJ.distance.inter = struct();

OBJ.distance.inter.kl = nan(use_syllables, use_syllables);
OBJ.distance.inter.bc = nan(use_syllables, use_syllables);
OBJ.distance.inter.ml = nan(use_syllables, use_syllables);

fprintf('Computing KL divergence...\n');

upd = kinect_extract.proc_timer(use_syllables);

for i = 1:use_syllables

    idx1 = OBJ.behavior(1).original_states(i) + 1;

    m1 = kinect_model.get_stationary_mean(OBJ.behavior(1).parameters.ar_mat(idx1, :, :));
    s1 = kinect_model.get_stationary_cov(OBJ.behavior(1).parameters.ar_mat(idx1, :, :), OBJ.behavior(1).parameters.sig(idx1, :, :));

    A1 = kinect_model.get_canonical_matrix(OBJ.behavior(1).parameters.ar_mat(idx1, :, :));

    e1 = eig(A1);

    for j = 1:use_syllables

        idx2 = OBJ.behavior(1).original_states(j) + 1;

        A2 = kinect_model.get_canonical_matrix(OBJ.behavior(1).parameters.ar_mat(idx2, :, :));
        e2 = eig(A2);

        s2 = kinect_model.get_stationary_cov(OBJ.behavior(1).parameters.ar_mat(idx2, :, :), OBJ.behavior(1).parameters.sig(idx2, :, :));
        m2 = kinect_model.get_stationary_mean(OBJ.behavior(1).parameters.ar_mat(idx2, :, :));

        stable = all(abs(e2) <= 1 + 1e-1) | all(abs(e1) <= 1 + 1e-1);

        if ~stable
            continue;
        end

        ave_s = (s1 + s2) * .5;
        ave_m = (m1 + m2) * .5;

        kl1 = kinect_model.get_gaussian_kl(m1, s1, ave_m, ave_s);
        kl2 = kinect_model.get_gaussian_kl(m2, s2, ave_m, ave_s);

        OBJ.distance.inter.kl(i, j) = .5 * (kl1 + kl2);

    end

    upd(i);

end

upd(inf);
OBJ.distance.inter.kl(eye(size(OBJ.distance.inter.kl)) == 1) = 0;

if ~isempty(OBJ.projections)

    fprintf('Computing scalar distances...\n');

    use_scalars = fieldnames(OBJ.projections(1).scalars);
    use_scalars(contains(use_scalars, 'centroid')) = [];
    use_scalars(contains(use_scalars, 'pca')) = [];
    use_scalars(contains(use_scalars, 'duration')) = [];

    sliced_scalars = OBJ.slice_syllables_scalars(use_scalars, 1:OBJ.options.syllable_cutoff);

    upd = kinect_extract.proc_timer(length((use_scalars)));

    for i = 1:length(use_scalars)

        tmp = nan(10, use_syllables);

        for j = 1:use_syllables

            if contains(use_scalars{i}, 'angle')
                tmp2 = diff(cat(2, sliced_scalars(j, :).(use_scalars{i})));
                tmp2 = [zeros(1, size(tmp2, 2)); tmp2];
            else
                tmp2 = (cat(2, sliced_scalars(j, :).(use_scalars{i})));
            end

            tmp(:, j) = nanmean(tmp2(OBJ.options.max_lag_scalars:OBJ.options.max_lag_scalars + 9, :), 2);
        end

        OBJ.distance.inter.scalars.(use_scalars{i}) = squareform(pdist(tmp', 'correlation'));
        upd(i);

    end

    clear sliced_scalars;

    upd(inf);

end

if isfield(OBJ.projections, 'pca') & ~isempty(OBJ.projections(1).pca)

    fprintf('Getting AR distances...\n');

    use_init = 3;

    sliced_pca = OBJ.slice_syllables_scalars({'pca'}, 1:OBJ.options.syllable_cutoff);
    npcs = size(sliced_pca(1).pca, 2);
    use_samples = [use_init 10];
    coefficients = nan(length(-use_samples(1):use_samples(2)), npcs, use_syllables);

    smps = length(-use_samples(1):use_samples(2));
    pca_scores = nan(smps, 10, use_syllables);

    upd = kinect_extract.proc_timer(use_syllables);

    for i = 1:use_syllables
        tmp = (cat(3, sliced_pca(i, :).pca));
        pca_scores(:, :, i) = nanmean(tmp(OBJ.options.max_lag_scalars - use_samples(1):OBJ.options.max_lag_scalars + use_samples(2), :, :), 3);
        upd(i);
    end

    upd(inf);

    tmp = reshape(pca_scores, [], use_syllables);
    OBJ.distance.inter.pca = squareform(pdist(tmp', 'correlation'));

    sim_points = 100;
    sim_coefficients = nan(sim_points, 10, use_syllables);

    upd = kinect_extract.proc_timer(use_syllables);

    for i = 1:use_syllables

        cur_ar = squeeze(OBJ.behavior(1).parameters.ar_mat(OBJ.behavior(1).original_states(i) + 1, :, :));

        % first 10 columns are lag 1, and so on, with the last column being the
        % affine term

        % sim the ar process

        lag3 = cur_ar(:, 1:10);
        lag2 = cur_ar(:, 11:20);
        lag1 = cur_ar(:, 21:30);
        af = cur_ar(:, 31);

        init_points = pca_scores(1:use_init, :, i)';

        sim_vec = nan(10, sim_points);
        sim_vec(:, 1:use_init) = init_points;

        tpoint = use_init + 1;

        for j = use_init + 1:sim_points
            sim_vec(:, tpoint) = lag1 * sim_vec(:, tpoint - 1) + lag2 * sim_vec(:, tpoint - 2) + lag3 * sim_vec(:, tpoint - 3) + af;
            tpoint = tpoint + 1;
        end

        sim_coefficients(:, :, i) = sim_vec';
        upd(i);

    end

    upd(inf);
    tmp = reshape((sim_coefficients(use_init:use_init + 9, :, :)), [], use_syllables);
    OBJ.distance.inter.ar = squareform(pdist(tmp', 'correlation'));

    % ar impulse response as well?

    ar_vec = squareform(OBJ.distance.inter.ar(1:use_syllables, 1:use_syllables), 'tovector');
    height_ave_vec = squareform(OBJ.distance.inter.scalars.height_ave(1:use_syllables, 1:use_syllables), 'tovector');
    angle_vec = squareform(OBJ.distance.inter.scalars.angle(1:use_syllables, 1:use_syllables), 'tovector');
    vel_vec = squareform(OBJ.distance.inter.scalars.velocity_mag(1:use_syllables, 1:use_syllables), 'tovector');

    % normalize and recombine

    dist_mat = mean(zscore([ar_vec(:) height_ave_vec(:)]), 2);
    dist_mat = squareform(dist_mat);
    dist_mat = squareform(dist_mat, 'tovector');

    dist_mat = (dist_mat - min(dist_mat)) ./ (max(dist_mat) - min(dist_mat));
    OBJ.distance.inter.combined = squareform(dist_mat);

end

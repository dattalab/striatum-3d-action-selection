function AR_COEFFS = get_ar_trajectory(OBJ, BEH, INIT)
%
%
%
%

if nargin < 3 | isempty(INIT)
    INIT = 'pca';
end

if nargin < 2 | isempty(BEH)
    BEH = 1;
end

if strcmp(lower(INIT(1)), 'p')
    assert(isfield(OBJ.stats.model_scalars, 'pca') & ~isempty(OBJ.stats.model_scalars(1).pca), 'Needs PCs to use PCA initialization');
end

assert(strcmp(lower(INIT(1)), 'p'), 'Only PCA initialization is valid');

use_init = 3;

npcs = size(OBJ.stats.model_scalars(1).pca, 2);
use_samples = [use_init 10];

smps = length(-use_samples(1):use_samples(2));

tmp = (cat(3, OBJ.stats.model_scalars(BEH, :).pca));
pca_scores = squeeze(nanmean(tmp(OBJ.options.max_lag_scalars - use_samples(1):OBJ.options.max_lag_scalars + use_samples(2), :, :), 3));

sim_points = 100;
cur_ar = squeeze(OBJ.behavior(1).parameters.ar_mat(OBJ.behavior(1).original_states(BEH) + 1, :, :));

% first 10 columns are lag 1, and so on, with the last column being the
% affine term

% sim the ar process

lag3 = cur_ar(:, 1:10);
lag2 = cur_ar(:, 11:20);
lag1 = cur_ar(:, 21:30);
af = cur_ar(:, 31);

init_points = pca_scores';

sim_vec = nan(10, sim_points);
sim_vec(:, 1:use_init) = init_points(:, 1:use_init);

tpoint = use_init + 1;

for j = use_init + 1:sim_points
    sim_vec(:, tpoint) = lag1 * sim_vec(:, tpoint - 1) + lag2 * sim_vec(:, tpoint - 2) + lag3 * sim_vec(:, tpoint - 3) + af;
    tpoint = tpoint + 1;
end

AR_COEFFS = sim_vec';

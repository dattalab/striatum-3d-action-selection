function H = scatter_density(X, Y, DENSITY, SMOOTHING)
%
%
%
%
%

if nargin < 4 | isempty(SMOOTHING)
    SMOOTHING = [];
end

if nargin < 3 | isempty(DENSITY)
    DENSITY = [sqrt(numel(X)) sqrt(numel(Y))];
end

X = X(:);
Y = Y(:);

x_bins = linspace(min(X), max(X), DENSITY(1));
y_bins = linspace(min(Y), max(Y), DENSITY(2));

hist_mat = zeros(numel(y_bins), numel(x_bins));
bin_idx = zeros(numel(X), 2);

[~, bin_idx(:, 1)] = histc(Y, y_bins);
[~, bin_idx(:, 2)] = histc(X, x_bins);

bin_idx(any(isnan(bin_idx')), :) = [];

hist_mat = accumarray(bin_idx, 1, size(hist_mat));

if ~isempty(SMOOTHING)
    hist_mat = imgaussfilt(hist_mat, SMOOTHING, 'padding', 'symmetric');
end

density = nan(numel(X), 1);

for i = 1:length(X)
    density(i) = hist_mat(bin_idx(i, 1), bin_idx(i, 2));
end

scatter(X, Y, 10, density(:), 'filled')

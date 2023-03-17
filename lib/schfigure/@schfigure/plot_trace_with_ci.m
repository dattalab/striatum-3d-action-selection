function AX = plot_trace_with_ci(X, DATA, BOOTS, varargin)
%
%
%
%

X = X(:)';
assert(size(DATA, 2) == size(BOOTS, 2), 'bootstraps do not have the same dimension as data')

opts = struct( ...
    'line_color', 'k', ...
    'line_style', 'k-', ...
    'face_color', [1 0 0], ...
    'edge_color', 'none', ...
    'sigma_t', 1, ...
    'plot_fun', @(x) nanmean(x), ...
    'labels', '');

opts_names = fieldnames(opts);
nparams = length(varargin);

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

use_params = [];

for i = 1:2:nparams

    if any(strcmp(varargin{i}, opts_names))
        opts.(varargin{i}) = varargin{i + 1};
    end

end

se = opts.sigma_t .* nanstd(BOOTS);
mu = opts.plot_fun(DATA);
ci = [mu - se; mu + se];

AX(1) = schfigure.shaded_errorbar(X, ci, opts.face_color, opts.edge_color);
hold on;
AX(2) = plot(X, mu, opts.line_style, 'color', opts.line_color);

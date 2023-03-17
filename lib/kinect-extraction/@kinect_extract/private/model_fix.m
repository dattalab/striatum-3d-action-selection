function STATS = kinect_model_fix(STATS, LHOODS, varargin)
%
%
%
%

alpha_scale = 1e5;
lhood_scale = 'sq';
smooth_vars = {'Centroid', 'Orientation'};
rate_thresh = [0 1];

nparams = length(varargin);

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

for i = 1:2:nparams

    switch lower(varargin{i})
        case 'alpha_scale'
            alpha_scale = varargin{i + 1};
        case 'lhood_scale'
            lhood_scale = varargin{i + 1};
        case 'smooth_vars'
            smooth_vars = varargin{i + 1};
        case 'rate_thresh'
            thresh = varargin{i + 1};
        otherwise
    end

end

% forward pass

switch lower(lhood_scale)
    case 'sq'
        LHOODS = LHOODS .^ 2;
    case 'log'
        LHOODS = log(LHOODS);
end

rate = LHOODS * alpha_scale;

if ~isempty(rate_thresh)
    rate(rate < (rate_thresh(1))) = 0;
    rate(rate > (rate_thresh(2))) = 1;
end

fprintf('Model-based smoothing, forward pass...\n');

for i = 2:length(STATS)

    for j = 1:length(smooth_vars)
        STATS{i}.(smooth_vars{j}) = STATS{i}.(smooth_vars{j}) * rate(i) + STATS{i - 1}.(smooth_vars{j}) * (1 - rate(i));
    end

end

fprintf('Model-based smoothing, backward pass...\n');

for i = length(STATS) - 1:-1:2

    for j = 1:length(smooth_vars)
        STATS{i}.(smooth_vars{j}) = STATS{i}.(smooth_vars{j}) * rate(i) + STATS{i + 1}.(smooth_vars{j}) * (1 - rate(i));
    end

end

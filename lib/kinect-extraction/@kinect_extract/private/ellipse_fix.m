function [STATS, PARAMETERS] = kinect_ellipse_fix(STATS, varargin)
%
%
%
%

hampel_span = 13;
hampel_sigma = 1;
smooth_span = 9;

nparams = length(varargin);

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

for i = 1:2:nparams

    switch lower(varargin{i})
        case 'hampel_span'
            span = varargin{i + 1};
        case 'hampel_sigma'
            hampel_sigma = varargin{i + 1};
        case 'smooth_span'
            smooth_span = varargin{i + 1};
        otherwise
    end

end

PARAMETERS = nan(2, length(STATS));

for i = 1:length(STATS)

    if ~isempty(STATS{i})
        %PARAMETERS(1,i)=STATS{i}.Eccentricity;
        PARAMETERS(1, i) = STATS{i}.MajorAxisLength;
        PARAMETERS(2, i) = STATS{i}.MinorAxisLength;
    end

end

% first pass get rid of outliers w/ hampel filter

if hampel_span > 0

    for i = 1:size(PARAMETERS, 1)
        PARAMETERS(i, :) = hampel(PARAMETERS(i, :), hampel_span, hampel_sigma);
    end

end

idx = 1:size(PARAMETERS, 2);

% impute missing data

for i = 1:size(PARAMETERS, 1)
    nanidx = isnan(PARAMETERS(i, :));
    PARAMETERS(i, nanidx) = interp1(idx(~nanidx), PARAMETERS(i, ~nanidx), idx(nanidx), 'spline');
end

% smooth

if smooth_span > 0

    for i = 1:size(PARAMETERS, 1)
        PARAMETERS(i, :) = smooth(PARAMETERS(i, :), smooth_span, 'rlowess');
    end

end

% check for outliers again

if hampel_span > 0

    for i = 1:size(PARAMETERS, 1)
        PARAMETERS(i, :) = hampel(PARAMETERS(i, :), hampel_span, hampel_sigma);
    end

end

% put back into stats structure

for i = 1:length(STATS)
    %STATS{i}.Eccentricity=PARAMETERS(1,i);
    STATS{i}.MajorAxisLength = PARAMETERS(1, i);
    STATS{i}.MinorAxisLength = PARAMETERS(2, i);
end

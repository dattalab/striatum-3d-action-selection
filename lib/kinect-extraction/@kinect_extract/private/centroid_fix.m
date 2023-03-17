function [STATS, POSITIONS] = kinect_centroid_fix(STATS, varargin)
%
%
%
%

threshold = inf; % common setting might be 5
hampel_span = 13;
hampel_sigma = 1;
smooth_span = 0;
use_field = 'Centroid';

nparams = length(varargin);

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

for i = 1:2:nparams

    switch lower(varargin{i})
        case 'hampel_span'
            hampel_span = varargin{i + 1};
        case 'hampel_sigma'
            hampel_sigma = varargin{i + 1};
        case 'smooth_span'
            smooth_span = varargin{i + 1};
        case 'use_field'
            use_field = varargin{i + 1};
        case 'threshold'
            threshold = varargin{i + 1};
        otherwise
    end

end

if iscell(STATS)
    POSITIONS = nan(2, length(STATS));

    for i = 1:length(STATS)

        if ~isempty(STATS{i}) & isfield(STATS{i}, use_field)
            POSITIONS(:, i) = STATS{i}.(use_field);
        end

    end

elseif isstruct(STATS)
    POSITIONS = nan(2, length(STATS));

    for i = 1:length(STATS)

        if ~isempty(STATS(i)) & isfield(STATS(i), use_field)
            POSITIONS(:, i) = STATS(i).(use_field);
        end

    end

else
    POSITIONS = STATS;
end

% get the Euclidean distance between neighboring points
% (probably only need to check lag 1 for the moment)

if hampel_span > 0
    POSITIONS(1, :) = hampel(POSITIONS(1, :), hampel_span, hampel_sigma);
    POSITIONS(2, :) = hampel(POSITIONS(2, :), hampel_span, hampel_sigma);
end

idx = 1:size(POSITIONS, 2) - 1;
euclid_diff = sqrt(sum((POSITIONS(:, idx) - POSITIONS(:, idx + 1)) .^ 2));
newidx = find(euclid_diff > threshold) + 1;
newidx2 = find(isnan(POSITIONS(1, :)) | isnan(POSITIONS(2, :)));
jumps = false(1, length(STATS));
jumps(unique([newidx(:); newidx2(:)])) = true;

% grab increasingly non-local info until jumps disappear

counter = 0;

while any(jumps)
    idx = 1:size(POSITIONS, 2);

    POSITIONS(1, jumps) = interp1(idx(~jumps), POSITIONS(1, ~jumps), idx(jumps), 'spline');
    POSITIONS(2, jumps) = interp1(idx(~jumps), POSITIONS(2, ~jumps), idx(jumps), 'spline');

    idx = POSITIONS(1, :) < 1;
    POSITIONS(1, idx) = 1;
    idx = POSITIONS(2, :) < 1;
    POSITIONS(2, idx) = 1;

    idx = 1:size(POSITIONS, 2) - 1;

    euclid_diff = sqrt(sum((POSITIONS(:, idx) - POSITIONS(:, idx + 1)) .^ 2));

    newidx = find(euclid_diff > threshold) + 1;
    jumps = zeros(1, length(STATS));
    jumps(newidx) = 1;
    jumps = conv(jumps, ones(counter, 1), 'same') > 0;

    counter = counter + 1;
end

if hampel_span > 0
    POSITIONS(1, :) = hampel(POSITIONS(1, :), hampel_span, hampel_sigma);
    POSITIONS(2, :) = hampel(POSITIONS(2, :), hampel_span, hampel_sigma);
end

if smooth_span > 0
    POSITIONS(1, :) = smooth(POSITIONS(1, :), smooth_span, 'rlowess');
    POSITIONS(2, :) = smooth(POSITIONS(2, :), smooth_span, 'rlowess');
end

fprintf('Interpolated position %i rounds\n', counter);

if iscell(STATS)

    for i = 1:length(STATS)
        STATS{i}.(use_field) = round(POSITIONS(:, i))';
    end

elseif isstruct(STATS)

    for i = 1:length(STATS)
        STATS(i).(use_field) = round(POSITIONS(:, i))';
    end

else
    STATS = POSITIONS;
end

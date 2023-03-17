function [STATS, ANGLES] = kinect_angle_fix(STATS, TOL, varargin)
%
%
%
%

hampel_span = 13;
hampel_sigma = 1;
smooth_span = 5;
max_iters = 1e6;

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

if nargin < 2 | isempty(TOL)
    TOL = pi / 2;
end

ANGLES = nan(1, length(STATS));

for i = 1:length(STATS)

    if ~isempty(STATS{i}) & isfield(STATS{i}, 'Orientation')
        ANGLES(i) = STATS{i}.Orientation * pi / 180;
    end

end

angles_complex = exp(1j .* ANGLES);

% interpolate the angles

idx = [1:length(ANGLES)];
nans = isnan(ANGLES);
angles_complex(nans) = interp1(idx(~nans), angles_complex(~nans), idx(nans), 'spline');
ANGLES = angle(angles_complex);

% walk along the vector, fixing angles as we go along

idx = [1:length(ANGLES) - 1];
angles_df = diff(ANGLES);

% jumps are points where angles_df==2

jumps = abs(angles_df) >= (pi - TOL);

% fix the largest jumps first, will need image confirmation for more subtle jumps

i = 0;

while any(jumps) & i < max_iters
    first_jump = min(find(jumps));
    first_jump_sign = sign(angles_df(first_jump));

    if first_jump_sign == 1
        ANGLES(first_jump + 1:end) = ANGLES(first_jump + 1:end) - pi;
    else
        ANGLES(first_jump + 1:end) = ANGLES(first_jump + 1:end) + pi;
    end

    angles_df = diff(ANGLES);
    jumps = abs(angles_df) >= (pi - TOL);
    i = i + 1;
end

if hampel_span > 0
    ANGLES = hampel(ANGLES, hampel_span, hampel_sigma);
end

if smooth_span > 0
    ANGLES = smooth(ANGLES, smooth_span, 'rlowess');
end

for i = 1:length(STATS)
    STATS{i}.Orientation = ANGLES(i) * 180 / pi;
end

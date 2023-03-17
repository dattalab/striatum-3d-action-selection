function STATS = im_stats(FRAMES, MASK, varargin)
%

nparams = length(varargin);
maxdots = 50;
suppress_output = false;
mask = [];
low = [];
high = [];
weighted_centroid = false;
use_cc = false;
scale = 'lin';
boot_frac = 1;
nboots = 1;
med_filt_size = [3 3];
open_size = 3;
open_reps = 1;
beta = 2e-7;
low_raw = 10;
high_raw = 100;

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

for i = 1:2:nparams

    switch lower(varargin{i})
        case 'suppress_output'
            suppress_output = varargin{i + 1};
        case 'mask'
            mask = varargin{i + 1};
        case 'low'
            low = varargin{i + 1};
        case 'high'
            high = varargin{i + 1};
        case 'weighted_centroid'
            weighted_centroid = varargin{i + 1};
        case 'use_cc'
            use_cc = varargin{i + 1};
        case 'scale'
            scale = varargin{i + 1};
        case 'nboots'
            nboots = varargin{i + 1};
        case 'boot_frac'
            boot_frac = varargin{i + 1};
        case 'open_reps'
            open_reps = varargin{i + 1};
        case 'open_size'
            open_size = varargin{i + 1};
        case 'med_filt_size'
            med_filt_size = varargin{i + 1};
        case 'nboots'
            nboots = varargin{i + 1};
        case 'beta'
            beta = varargin{i + 1};
        case 'low_raw'
            low_raw = varargin{i + 1};
        case 'high_raw'
            high_raw = varargin{i + 1};
        otherwise
    end

end

[height, width, nframes] = size(FRAMES);
STATS = cell(1, nframes);

if nframes > maxdots
    dot_width = maxdots;
    convert_factor = round(nframes / maxdots);
else
    convert_factor = 1;
end

if ~suppress_output
    fprintf('Progress interpolating through cable:\n');
    fprintf(['\n' repmat('.', 1, dot_width) '\n\n']);
end

% TODO:  chuck the cell array, making things too painful

parfor i = 1:nframes

    if ~suppress_output

        if mod(i, convert_factor) == 0
            fprintf('\b|\n');
        end

    end

    % get connected components and relevant blob parameters...

    % pre-process frame at all?

    tmp = FRAMES(:, :, i);

    if ~isempty(MASK)

        tmp_mask = MASK(:, :, i);

        if strcmp(lower(scale(1:3)), 'log')
            tmp_mask = log(tmp_mask + beta);
        end

        if ~isempty(high)
            flag1 = tmp_mask < high;
        else
            flag1 = true(size(tmp));
        end

        if ~isempty(low)
            flag2 = tmp_mask > low;
        else
            flag2 = true(size(tmp));
        end

    else
        flag1 = true(size(tmp));
        flag2 = true(size(tmp));
    end

    mask = cast(flag1 & flag2, 'like', tmp);
    tmp = tmp .* mask;

    tmp = process_frame(tmp, ...
        'open_reps', open_reps, 'open_size', open_size, ...
        'med_filt_size', med_filt_size);

    binary = false;

    if ~isempty(low_raw)
        flag1 = tmp > low_raw;
        binary = true;
    else
        flag1 = true(size(tmp));
    end

    if ~isempty(high_raw)
        flag2 = tmp < high_raw;
        binary = true;
    else
        flag2 = true(size(tmp));
    end

    if binary
        tmp = flag1 & flag2;
    end

    % either use cc of take all points that pass our criteria

    if use_cc
        tmp = kinect_extract.get_largest_blob(tmp);
    end

    % get coeff

    features = im_moment_features(tmp);

    STATS{i}.MajorAxisLength = features.AxisLength(1);
    STATS{i}.MinorAxisLength = features.AxisLength(2);
    STATS{i}.Centroid = features.Centroid;
    STATS{i}.Orientation = features.Orientation;
    STATS{i}.Skewness = features.Skewness;

    % let's compute these manually, disambiguate using third order moments?

    [STATS{i}.EllipseX, STATS{i}.EllipseY] = ellipse_fit(STATS{i});

end

if ~suppress_output
    fprintf('\n');
end

function FRAME = kinect_process_frame(FRAME, varargin)
%
%
%
%
%

open_reps = [];
open_size = [];
dilate_reps = [];
dilate_size = [];
ord_size_space = [];
ord_num_space = [];
med_filt_size = [];
med_filt_time = [];
hampel_span = [];
hampel_sigma = [];

nparams = length(varargin);

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

for i = 1:2:nparams

    switch lower(varargin{i})
        case 'open_reps'
            open_reps = varargin{i + 1};
        case 'open_size'
            open_size = varargin{i + 1};
        case 'dilate_reps'
            dilate_reps = varargin{i + 1};
        case 'dilate_size'
            dilate_size = varargin{i + 1};
        case 'low'
            low = varargin{i + 1};
        case 'high'
            high = varargin{i + 1};
        case 'ord_size_space'
            ord_size_space = varargin{i + 1};
        case 'ord_num_space'
            ord_num_space = varargin{i + 1};
        case 'med_filt_size'
            med_filt_size = varargin{i + 1};
        case 'med_filt_time'
            med_filt_time = varargin{i + 1};
        case 'hampel_span'
            hampel_span = varargin{i + 1};
        case 'hampel_sigma'
            hampel_sigma = varargin{i + 1};
        otherwise
    end

end

data_type = class(FRAME);
[rows, columns, nframes] = size(FRAME);

if isinteger(FRAME)
    missing_idx = FRAME == intmin(data_type);
    FRAME = single(FRAME);
    FRAME(missing_idx) = nan;
elseif isfloat(FRAME)
    missing_idx = isnan(FRAME);
else
    missing_idx = false(size(FRAME));
end

if ~isempty(hampel_span) & ~isempty(hampel_sigma)
    FRAME = reshape(FRAME, rows * columns, [])';

    % stride across columns, I know this sucks but this is way too memory intensive for now

    outliers = false(size(FRAME));

    parfor i = 1:rows * columns
        [~, outliers(:, i)] = hampel(FRAME(:, i), hampel_span, hampel_sigma);
    end

    outliers = reshape(outliers', rows, columns, []);
    missing_idx = missing_idx | outliers;
    clear outliers;
    FRAME = reshape(FRAME', rows, columns, []);
end

if length(ord_size_space) == 2 & all(ord_size_space > 0)

    parfor i = 1:nframes
        FRAME(:, :, i) = ordfilt2(FRAME(:, :, i), ord_num_space, true(ord_size_space + 2));
    end

end

if open_reps > 0 & open_size > 0
    % morpho on either mask or image itself?
    for i = 1:open_reps
        FRAME = imopen(FRAME, strel('disk', open_size));
    end

end

if dilate_reps > 0 & dilate_size > 0

    for i = 1:dilate_reps
        FRAME = imdilate(FRAME, strel('disk', dilate_size));
    end

end

if length(med_filt_size) == 2 & all(med_filt_size > 0)

    parfor i = 1:nframes
        FRAME(:, :, i) = medfilt2(FRAME(:, :, i), med_filt_size);
    end

end

if ~isempty(med_filt_time)
    FRAME = reshape(FRAME, rows * columns, [])';

    for i = 1:length(med_filt_time)

        parfor j = 1:rows * columns
            FRAME(:, j) = medfilt1(FRAME(:, j), med_filt_time(i), 'omitnan');
        end

    end

    FRAME = reshape(FRAME', rows, columns, []);
end

% whatever we do, don't change the data type

nans = isnan(FRAME);
FRAME = cast(FRAME, data_type);

if isinteger(FRAME)
    FRAME(missing_idx | nans) = intmin(data_type);
elseif isfloat(FRAME)
    FRAME(missing_idx | nans) = nan;
end

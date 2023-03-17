function [BOX_FRAMES, BLANK] = kinect_mouse_bounding_box(FRAMES, CENTROIDS, varargin)
%

box_size = [160 160];
maxdots = 50;
suppress_output = false;
rotate = true;

nparams = length(varargin);

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

for i = 1:2:nparams

    switch lower(varargin{i})
        case 'box_size'
            box_size = varargin{i + 1};
        case 'suppress_output'
            suppress_output = varargin{i + 1};
        case 'rotate'
            rotate = varargin{i + 1};
        otherwise
    end

end

if any(mod(box_size, 2) ~= 0)
    error('Box size must be even');
end

[height, width, nframes] = size(FRAMES);

BOX_FRAMES = zeros(box_size(1), box_size(2), nframes, class(FRAMES));
box_size = round(box_size / 2); % account for center so we have exactly box size pixels
BLANK = [];
% correct any flips (mouse never immediately turns 180)...

if nframes > maxdots
    dot_width = maxdots;
    convert_factor = round(nframes / maxdots);
else
    convert_factor = 1;
end

if ~suppress_output
    fprintf('Progress cropping:\n');
    fprintf(['\n' repmat('.', 1, dot_width) '\n\n']);
end

parfor i = 1:nframes

    if ~suppress_output

        if mod(i, convert_factor) == 0
            fprintf('\b|\n');
        end

    end

    tmp = FRAMES(:, :, i);

    center = round(CENTROIDS(i, :));

    % place centroid at center pixel

    coords_x = [center(1) - (box_size(1) - 1):center(1) + box_size(1)];
    coords_y = [center(2) - (box_size(2) - 1):center(2) + box_size(2)];

    % make sure coordinates don't exceed the image...

    if any(coords_x < 1) | any(coords_x > width) | any(coords_y < 1) | any(coords_y > height)
        BLANK = [BLANK i];
        continue;
    end

    crop = tmp(coords_y, coords_x);
    BOX_FRAMES(:, :, i) = crop;

end

if ~suppress_output
    fprintf('\n');
end

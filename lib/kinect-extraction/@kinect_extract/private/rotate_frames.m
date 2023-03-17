function FRAMES = kinect_rotate(FRAMES, ANGLES, varargin)
%
%
%
%
%
%

maxdots = 50;
[height, width, nframes] = size(FRAMES);
suppress_output = false;
nparams = length(varargin);

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

for i = 1:2:nparams

    switch lower(varargin{i})
        case 'suppress_output'
            suppress_output = varargin{i + 1};
        otherwise
    end

end

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

% rotate memmap in place?

parfor i = 1:length(ANGLES)

    if ~suppress_output

        if mod(i, convert_factor) == 0
            fprintf('\b|\n');
        end

    end

    if ~isempty(ANGLES(i))
        FRAMES(:, :, i) = imrotate(FRAMES(:, :, i), ANGLES(i), 'bilinear', 'crop');
    end

end

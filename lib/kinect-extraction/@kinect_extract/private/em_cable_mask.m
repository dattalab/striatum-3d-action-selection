function CABLE_MASK = kinect_mouse_bounding_box_clean_em(FRAMES, MU, SIG, varargin)
%

maxdots = 50;
suppress_output = false;
nparams = length(varargin);
cable_thresh = -15;
open_reps = 1;
open_size = 3;

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

for i = 1:2:nparams

    switch lower(varargin{i})
        case 'suppress_output'
            suppress_output = varargin{i + 1};
        case 'cable_thresh'
            cable_thresh = varargin{i + 1};
        case 'open_reps'
            open_reps = varargin{i + 1};
        case 'open_size'
            open_size = varargin{i + 1};
        otherwise
    end

end

[height, width, nframes] = size(FRAMES);
center = round([width / 2; height / 2]);

CABLE_MASK = zeros(size(FRAMES), 'single');

% correct any flips (mouse never immediately turns 180)...

if nframes > maxdots
    dot_width = maxdots;
    convert_factor = round(nframes / maxdots);
else
    convert_factor = 1;
end

if ~suppress_output
    fprintf('Progress cleaning frames:\n');
    fprintf(['\n' repmat('.', 1, dot_width) '\n\n']);
end

[xx, yy] = meshgrid(1:width, 1:height);
xx = xx(:);
yy = yy(:);

% basic idea:

% 1)use mu and sig to estimate likelihoods
% 2) use likelihood threshold to detect cable
% 3) use x,y likelihood only (marginalize z) to estimate likely mouse position
% 4) sample conditional distribution at mouse&cable conjunction
% 5) alternatively, replace with random points conditioned on point in space

parfor i = 1:nframes

    if ~suppress_output

        if mod(i, convert_factor) == 0
            fprintf('\b|\n');
        end

    end

    % get the likelihood per frame

    %rot_angle=ANGLES(i);

    % rotate back to original angle

    %tmp=imrotate(FRAMES(:,:,i),rot_angle,'bilinear','crop');
    tmp = FRAMES(:, :, i);
    mu = MU(:, i)';
    sig = SIG(:, :, i);

    feature_mat = [xx yy double(tmp(:))];

    % sample w/ z

    mu(1:2) = round([height / 2 width / 2]);
    theta = mvnpdf(feature_mat, mu, sig);

    % true where there is mouse, false where there is cable (or no mouse)
    theta = reshape(theta, [height width]);

    % cable_mask=int16(theta>cable_thresh);
    %
    % if open_reps>0 & open_size>0
    %
    % 	% morpho on either mask or image itself?
    %
    % 	for j=1:open_reps
    % 		cable_mask=imopen(cable_mask,strel('disk',open_size));
    % 	end
    %
    % end

    % either mask out the bad pixels or draw from some conditional...
    % diffusion or region fill?

    CABLE_MASK(:, :, i) = theta;

end

if ~suppress_output
    fprintf('\n');
end

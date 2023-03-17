function [ZPROFILE, VEL] = make_spinogram(OBJ, varargin)
%
%
%

opts = struct( ...
    'width', 40, ...
    'syllable_idx', 1, ...
    'syllable', 1, ...
    'depth', 673.1, ...
    'min_duration', 4, ...
    'process_frames', true);

opts_names = fieldnames(opts);
nparams = length(varargin);

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

for i = 1:2:nparams

    if any(strcmp(varargin{i}, opts_names))
        opts.(varargin{i}) = varargin{i + 1};
    end

end

% get the indices for the behavior selected by the user, plot a sideways profile

if length(opts.syllable_idx) == 1

    starts = OBJ.behavior_model.state_starts{opts.syllable};
    stops = OBJ.behavior_model.state_stops{opts.syllable};

    if ~isempty(opts.min_duration)
        durs = stops - starts;
        starts(durs < opts.min_duration) = [];
        stops(durs < opts.min_duration) = [];
    end

    if length(starts) < opts.syllable_idx
        error('Cannot index into example %i', opts.syllable_idx);
    end

    % otherwise get our z profile homey

    frame_indices = starts(opts.syllable_idx):stops(opts.syllable_idx);

elseif length(opts.syllable_idx) > 1

    % if the user supplied to arguments, get those specific frames

    frame_indices = opts.syllable_idx;

end

frames = OBJ.load_oriented_frames('process_frames', opts.process_frames, 'frame_idx', frame_indices);
centroid = OBJ.tracking.centroid;
[xw, yw] = kinect_extract.convert_pxs_to_mm(centroid(frame_indices, 1), centroid(frame_indices, 2), opts.depth);
vel = diff([xw(:) yw(:)]);
VEL = [0; hypot(vel(:, 1), vel(:, 2))];

% clean up?

frames(frames < 5) = 0;
[r, c, nframes] = size(frames);
midpoints = [floor(r / 2) floor(c / 2)];
ZPROFILE = squeeze(mean(frames(midpoints - opts.width / 2:midpoints + opts.width / 2, :, :)));

function correct_flips(OBJ, FORCE_FIX, USE_ORIGINAL_ANGLES)
%correct_flips- If you have a flip model or a file with flip locations, fix the flips in cropped, oriented data.
%
% Usage: obj.correct_flips(force_fix,use_original_angles)
%
% Inputs:
%   force_fix (bool): even if flips have been fixed before, correct flips again if set to true (default: false)
%   use_original_angles (bool): load the original angles, pre-all corrections (default: false)
%
% Options (obj.options.flip):
%   model_smoothing (int): number of frames for median smoothing of class probabilities (default: 50)
%   method (string): how to correct flips ('n' for none, 'f' for file, 'm' for model, default: 'n')
%
% Example 1:
%   obj.flip_tool; % fix Flips, be sure to save in GUI
%   obj.set_option('flip','method','f');
%   obj.correct_flips(true); % force the fix in case we've already run extraction routines
%
% Example 2:
%   obj.set_file('flip_model','location_of_flip_classifier.mat'); % set the location of the flip classifier
%   obj.set_option('flip','method','m'); % set method to (m)odel
%   obj.correct_flips(true); % fix the flips
%

if length(OBJ) > 1
    error('Object arrays not supported for this function.');
end

OBJ.update_status;

if nargin < 3 | isempty(USE_ORIGINAL_ANGLES)
    USE_ORIGINAL_ANGLES = false;
end

if nargin < 2 | isempty(FORCE_FIX)
    FORCE_FIX = false;
end

if OBJ.has_cable

    if ~(OBJ.status.orient & OBJ.status.orient_cable_mask)
        fprintf('Object not ready for flip correction.\n');
        return;
    end

else

    if ~(OBJ.status.orient & OBJ.status.get_mouse_mask)
        fprintf('Object not ready for flip correct.\n');
        return;
    end

end

if isempty(OBJ.tracking)
    OBJ.load_track_stats;
end

fprintf('Correcting flips...\n');

opts = OBJ.options.flip;

load(OBJ.files.track_stats{1}, 'angles_fixed');
nframes = OBJ.metadata.nframes;

flip_vector = true(1, nframes);

% use a logical vector to specify incorrect or correct facing directions
% everything up until the first flip is facing to the RIGHT (indicated by one)

if ~angles_fixed | FORCE_FIX

    load(OBJ.files.track_stats{1}, 'depth_stats_fixed');

    % TODO: simply re-orient the bounded mouse, more reversible...
    % only reuse angles if we force the fix...

    if (~FORCE_FIX & ~isfield(depth_stats_fixed(1), 'CorrectedOrientation')) | USE_ORIGINAL_ANGLES
        fprintf('Copying original angles to new field...\n');

        for i = 1:length(depth_stats_fixed)
            depth_stats_fixed(i).CorrectedOrientation = depth_stats_fixed(i).Orientation;
        end

    elseif FORCE_FIX & isfield(depth_stats_fixed(1), 'CorrectedOrientation')
        % use old corrected orientation (maybe second round of angle fixing)
    end

    if strcmp(opts.method, 'f') & OBJ.files.flip{2}
        fprintf('Collecting flips from file...\n');
        flips = read_flip_file(OBJ.files.flip{1});

        for i = 1:length(flips)

            % flip the bits to indicate the presence of a problem

            flip_vector(flips(i):end) = ~flip_vector(flips(i):end);

        end

    elseif strcmp(opts.method, 'n')

        fprintf('No flips...\n')
        % if no model and no flip file, assume we're all good

    elseif strcmp(opts.method, 'm') & OBJ.status.flip_model

        % use the model!

        % if user didn't load the model (passed as string, load first)

        if isempty(OBJ.flip_model)
            fprintf('Loading %s\n', OBJ.files.flip_model{1});
            load(OBJ.files.flip_model{1}, 'rnd_forest');
            OBJ.flip_model = rnd_forest;
        end

        flip_col = str2double(OBJ.flip_model.ClassNames) == 0;

        features = OBJ.load_oriented_frames;
        features = reshape(features, size(features, 1) ^ 2, [])';

        steps = 0:OBJ.frame_stride:nframes;
        steps = unique([steps nframes]);

        fprintf('Predicting flips with random forest...\n');

        timer_upd = kinect_extract.proc_timer(length(steps) - 1);
        proba = nan(nframes, 2);

        for i = 1:length(steps) - 1

            left_edge = steps(i);
            right_edge = steps(i + 1);

            [~, proba(left_edge + 1:right_edge, :)] = predict(OBJ.flip_model, single(features(left_edge + 1:right_edge, :)));
            timer_upd(i);

        end

        clear features;

        if opts.model_smoothing > 0
            fprintf('Smoothing prediction probabilities...\n');
            proba(:, 1) = medfilt1(proba(:, 1), opts.model_smoothing);
            proba(:, 2) = medfilt1(proba(:, 2), opts.model_smoothing);
        end

        flip_vector = (proba(:, ~flip_col) > proba(:, flip_col))';

    else
        error('Did not set options correctly, bailing...\n');
    end

end

% find all variables in depth_bounded_rotated, any 3D mats essentially

flip_idx = find(~flip_vector);

% rotate the data in place (equal to +/- 180 rotation), then add 180 to the
% fix the angles

if ~angles_fixed | FORCE_FIX

    fprintf('Fixing angles in depth_stats.mat...\n');

    for i = 1:length(flip_idx)

        % in degrees, flip by 180

        depth_stats_fixed(flip_idx(i)).CorrectedOrientation = depth_stats_fixed(flip_idx(i)).CorrectedOrientation + 180;

    end

    angles_fixed = true;
    fprintf('Saving new angles...\n');
    save(OBJ.files.track_stats{1}, 'depth_stats_fixed', 'angles_fixed', '-v7.3');

end

%ndim=length(file_info(i).size);

% check to make sure it hasn't already been fixed!

if ~isempty(flip_idx) | FORCE_FIX

    % recall, positive angles are counterclockwise rotations, negative clockwise
    % if flip idx is empty nothing happens here (which is intended)

    fprintf('Deleting old files...\n');

    if OBJ.status.movies_orient

        [pathname, filename, ~] = fileparts(OBJ.files.orient{1});
        [is_mov, filenames] = is_movie_file(fullfile(pathname, [filename '.*']));

        if is_mov

            for i = 1:length(filenames)
                fprintf('Deleting %s\n', filenames{i});
                delete(filenames{i});
            end

        end

    end

    if OBJ.files.orient{2}
        delete(OBJ.files.orient{1});
    end

    fprintf('Re-extracting data...\n');

    OBJ.update_status;
    OBJ.load_track_stats(true);
    OBJ.preprocess;

end

% re-write any movies that were deleted

OBJ.update_status;

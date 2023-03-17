classdef kinect_extract < handle & matlab.mixin.SetGet
% This class implements everything you need to extract raw data
% collected from the Kinect v2 (with or without cable)

% the essentials

properties

    mouse_id
    frame_stride
    use_tracking_model
    has_cable
    has_timer
    working_dir
    rois
    flip_model
    options
    missing_frames
    pca = kinect_pca
    behavior_model
    neural_data

end

% stuff the user can see but can't modify without using a class method

properties (GetAccess = public, SetAccess = private)

    average_image
    metadata
    tracking
    timestamps
    projections
    transform
    autoupdate = true

end

% the completely hidden stuff

properties (Access = private)

    status
    files

end

% have the pca object be a constant object, instance should be shared
% across an array of objects...

methods

    function obj = kinect_extract(DIR, AUTO_UPDATE)

        if nargin < 2
            AUTO_UPDATE = true;
        end

        if nargin < 1
            DIR = pwd;
        end

        % Constructs a kinect_extract object with the default Parameters

        obj.set_autoupdate(AUTO_UPDATE);
        obj.frame_stride = 500;
        obj.projections.pca = [];
        obj.projections.rp = [];
        obj.use_defaults;
        obj.working_dir = DIR;
        obj.has_cable = true;
        obj.has_timer = 0;
        obj.use_tracking_model = true;
        obj.pca.options = obj.options.pca;
        obj.metadata.groups = '';

        if obj.autoupdate
            obj.update_files;
            obj.update_status;
            obj.update_code_info;
        end

        if obj.files.roi{2} & obj.autoupdate
            obj.load_rois;
        end

        if obj.files.flip{2}
            obj.options.flip.method = 'f';
        end

        if obj.files.metadata{2} & obj.autoupdate
            obj.load_metadata;
            obj.mouse_id = obj.metadata.extract.SubjectName;
        end

        if (obj.files.depth_timestamps{2} | obj.files.rgb_timestamps{2}) & obj.autoupdate
            obj.load_timestamps;
        end

        obj.metadata.uuid = char(java.util.UUID.randomUUID);

    end

    % setting any of these options triggers a status update

    function obj = set.flip_model(obj, val)

        if isa(val, 'CompactTreeBagger')
            obj.flip_model = val;
            obj.options.flip.method = 'm';
            obj.update_status;
        elseif ischar(val)

            if exist(val, 'file') == 2
                obj.set_file('flip_model', val);
                obj.options.flip.method = 'm';
                obj.update_status;
            end

        end

    end

    function obj = set.has_cable(obj, val)

        if isa(val, 'logical') | isnumeric(val)
            obj.has_cable = logical(val);

            if val == true
                obj.use_tracking_model = true;
            end

            obj.update_status;
        end

    end

    function obj = set.use_tracking_model(obj, val)

        if isa(val, 'logical') | isnumeric(val)
            obj.use_tracking_model = logical(val);
            obj.update_status;
        end

    end

    function obj = set.working_dir(obj, val)
        % check if dir exists
        if exist(val, 'dir') > 0
            obj.working_dir = val;
            obj.update_status;
        end

    end

    function obj = set.metadata(obj, val)

        if isstruct(val)

            if isfield(val, 'extract')

                if isfield(val.extract, 'SubjectName')
                    obj.mouse_id = val.extract.SubjectName;
                end

            end

        end

        obj.metadata = val;
    end

    function s = saveobj(obj)
        s.projections = obj.projections;
        s.options = obj.options;
        s.pca = obj.pca;
        s.files = obj.files;
        s.behavior_model = obj.behavior_model;
        s.working_dir = obj.working_dir;
        s.average_image = obj.average_image;
        s.neural_data = obj.neural_data;
        s.timestamps = obj.timestamps;
        s.metadata = obj.metadata;
        s.transform = obj.transform;
        s.tracking = obj.tracking;
    end

end

methods (Static)

    % doesn't require the kinect_extract object

    [data labels names model_names] = prepare_data_for_flip_classifier(cat_data, training_fraction)
    upd = proc_timer(nloops, varargin)
    files = dir_recurse(dir, filter, maxdepth, maxdate, tag_name, tag_file, files, depth, skip)
    [states idx starts stops durations] = get_syllable_statistics(state_labels)
    data = clean_up_timeseries(data, max_dist)

    animate_direct(frames, varargin)
    deltac = delta_coefficients(data, win, zeropad)
    [pulse_number, pulse_position, pos_sample, neg_sample] = scan_pulse_train(use_trace, thresh, startcount)
    clock = convert_pulse_train_to_clock(pulsetrain, threshold)
    [x_mm, y_mm] = convert_pxs_to_mm(x, y, zw)
    mask = get_largest_blob(mask)

    function obj = loadobj(s)

        if isstruct(s)

            if ~exist(s.working_dir, 'dir')

                % first try the top-level, directory then reconstruct from path
                %fprintf('Reconstructing file tree...\n');
                tokens = regexp(s.working_dir, filesep, 'split');

                % from the current directory use top level to figure this thing out

                for i = 0:length(tokens) - 1
                    working_dir = pwd;
                    working_dir = fullfile(working_dir, tokens{end - i:end});

                    if exist(working_dir, 'dir')
                        break;
                    end

                end

            else

                working_dir = s.working_dir;

            end

            props = fieldnames(s);
            props(strcmp(props, 'working_dir')) = [];

            newobj = kinect_extract(working_dir, false);

            for i = 1:length(props)
                newobj.(props{i}) = s.(props{i});
            end

            if ~isfield(s, 'behavior_model') | isempty(s.behavior_model)
                newobj.behavior_model = kinect_model;
            end

            %newobj.update_status;
            obj = newobj;

        else
            obj = s;
        end

    end

end

end

classdef phanalysis < handle & matlab.mixin.SetGet
% the essentials, note that we intend for photometry and behavior
% objects to be arrays 'n stuff

properties

    stats
    photometry = hifiber
    imaging = hifiber
    behavior = kinect_model
    projections
    distance
    data_type = 'photometry'
    user_data = struct()

end

properties (GetAccess = public, SetAccess = private)

    options
    metadata
    session

end

properties (Access = private)

end

methods

    function obj = phanalysis(DATA, BEHAVIOR, KINECT, DATA_TYPE, UUID)

        if nargin < 5
            UUID = [];
        end

        if nargin < 4
            DATA_TYPE = [];
        end

        if nargin < 3
            KINECT = [];
        end

        if nargin < 2
            BEHAVIOR = [];
        end

        if nargin < 1
            DATA = [];
        end

        if ~isempty(DATA) & (length(BEHAVIOR) ~= length(DATA))
            error('Behavior and photometry objects must have the same number of sessions');
        end

        if ~isempty(DATA) & (length(DATA) ~= length(KINECT))
            error('Behavior and photometry objects must have the same number of sessions');
        end

        if ~isempty(DATA_TYPE)
            obj.data_type = DATA_TYPE;
        end

        obj.behavior = BEHAVIOR;

        switch lower(obj.data_type(1))
            case 'p'
                obj.photometry = DATA;
            case 'i'
                obj.imaging = DATA;
        end

        if ~isempty(KINECT)
            obj.load_session_metadata(KINECT);
            obj.use_defaults;
            obj.load_projections(KINECT);
        end

        if isempty(UUID)
            obj.metadata.uuid = char(java.util.UUID.randomUUID);
        else
            obj.metadata.uuid = UUID;
        end

    end

    % setting any of these options triggers a status update

    function s = saveobj(obj)
        use_names = properties(obj);

        %obj.convert_obj_to_struct;

        % too much memory, just recompute!

        for i = 1:length(use_names)

            if strcmp(use_names{i}, 'stats') & isfield(obj.(use_names{i}), 'model_starts') & isfield(obj.(use_names{i}), 'changepoints')
                s.(use_names{i}) = rmfield(obj.(use_names{i}), {'model_starts', 'changepoints'});
            elseif strcmp(use_names{i}, 'stats') & isfield(obj.(use_names{i}), 'model_starts')
                s.(use_names{i}) = rmfield(obj.(use_names{i}), {'model_starts'});
            else
                s.(use_names{i}) = obj.(use_names{i});
            end

        end

    end

end

% definitely want the ability to export

methods (Static)

    % doesn't require the kinect_extract object

    function obj = loadobj(s)

        if isstruct(s)
            use_names = fieldnames(s);
            obj = phanalysis;

            for i = 1:length(use_names)
                obj.(use_names{i}) = s.(use_names{i});
            end

        else
            obj = s;
        end

    end

    [shuffle_stat, save_mat, save_shuffles] = shuffle_statistic(fun, matrix, nshuffles, suppress_output);
    p = holm_bonf(p)
    deltac = compute_deltas(data, win, pad)
    print_stats(file, p, names, notes, varargin)
    data = nanzscore(data, modified)
    labels = clean_labels(labels)
    rnd_data = phase_randomize(data, nrands)
    [mat, col_idx] = vec_to_mat(data, nwin, noverlap)
    [wins win_t] = window_data(data, locs, win_size)
    signal = padded_conv(data, kernel, padding)
    data = get_original_timebase(idx, data)
    data = rolling_nanzscore(data, win, padding)

end

end

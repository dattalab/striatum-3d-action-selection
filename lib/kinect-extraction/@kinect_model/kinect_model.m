classdef kinect_model < handle
% This class implements everything you need to extract raw data
% collected from the Kinect v2 (with or without cable)

% the essentials

properties

    % initialize coefficients and parameters,
    % let this be used by kinect_extract for reconstruction, computing
    % scores, etc.

    % file for pc status etc

    working_dir
    model_path

end

% stuff the user can see but can't modify without using a class method

properties (GetAccess = public, SetAccess = {?kinect_pca, ?kinect_extract, ?phanalysis})

    labels
    states
    original_states
    state_idx
    state_starts
    state_stops
    state_durations
    transition_matrix
    parameters
    metadata
    sorted

end

properties (Access = {?kinect_pca, ?kinect_extract})

end

methods

    function obj = kinect_model(STATES, PARAMETERS, UUID)

        if nargin < 3
            UUID = [];
        end

        if nargin < 2
            PARAMETERS = [];
        end

        if nargin < 1
            STATES = [];
        end

        obj.labels = STATES(:);
        obj.parameters = PARAMETERS;
        obj.sorted = false;

        if isempty(UUID)
            obj.metadata.uuid = char(java.util.UUID.randomUUID);
        else
            obj.metadata.uuid = UUID;
        end

        if ~isempty(PARAMETERS)

            % ar matrix is the key to our dreambox

            if isfield(PARAMETERS, 'ar_mat')

                [nstates, npcs, d] = size(PARAMETERS.ar_mat);

                if mod(d, npcs) == 1
                    is_affine = true;
                else
                    is_affine = false;
                end

                obj.metadata.npcs = npcs;
                obj.metadata.is_affine = is_affine;
                obj.metadata.nstates = nstates;
                obj.metadata.kappa = PARAMETERS.kappa;
                obj.metadata.gamma = PARAMETERS.gamma;

                if isfield(obj.metadata, 'nu')
                    obj.metadata.nu = PARAMETERS.nu;
                else
                    obj.metadata.nu = [];
                end

            end

        end

    end

end

methods (Static)

    new_cov = get_stationary_cov(A, SIG)
    mu = get_stationary_mean(A, B)
    big_a = get_canonical_matrix(A)
    big_sig = get_canonical_sigma(SIG, NLAGS)
    kl = get_gaussian_kl(M1, S1, M2, S2)
    export_to_graphviz(trans_mat, varargin)
    export_to_table(trans_mat, varargin)
    idx = find_model(metadata, varargin)

end

end

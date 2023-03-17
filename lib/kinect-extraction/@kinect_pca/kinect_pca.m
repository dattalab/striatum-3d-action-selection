classdef kinect_pca < handle
% This class implements everything you need to extract raw data
% collected from the Kinect v2 (with or without cable)

% the essentials

properties

    % initialize coefficients and parameters,
    % let this be used by kinect_extract for reconstruction, computing
    % scores, etc.

    % file for pc status etc

    working_dir
    frame_stride

end

% stuff the user can see but can't modify without using a class method

properties (GetAccess = public, SetAccess = {?kinect_pca, ?kinect_extract, ?kinect_storage})

    coeffs
    details
    status
    missing_data

end

properties (Access = {?kinect_pca, ?kinect_extract})

    options

end

methods

    function s = saveobj(obj)
        s.frame_stride = obj.frame_stride;
        s.coeffs = obj.coeffs;
        s.details = obj.details;
        s.status = obj.status;
        s.missing_data = obj.missing_data;
    end

    function obj = kinect_pca(DIR)

        if nargin < 1
            DIR = fullfile(pwd, 'analysis');
        end

        % pc object constructor, note that the most common config is to have
        % this as a static data object in a kinect_extract array

        obj.working_dir = DIR;
        obj.update_status;
        obj.frame_stride = 500;

        % set of default status

    end

end

methods (Static)

    [coeffts, latent, explained, cov] = parallel_pca(data, varargin)
    ll = profile_likelihood(latent)

    function obj = loadobj(s)

        if isstruct(s)

            props = fieldnames(s);
            newobj = kinect_pca;

            for i = 1:length(props)
                newobj.(props{i}) = s.(props{i});
            end

            newobj.update_status;
            obj = newobj;

        else
            obj = s;

        end

    end

end

end

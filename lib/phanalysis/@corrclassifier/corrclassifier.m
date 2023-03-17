classdef corrclassifier < handle & matlab.mixin.SetGet

properties

    templates = [];
    classes = '';

end

% stuff the user can see but can't modify without using a class method
properties (GetAccess = public, SetAccess = private)

    options
    nclasses = 0;
    ndims = 0;

end

% the completely hidden stuff

properties (Access = private)

end

methods

    function obj = corrclassifier

        obj.use_defaults;

    end

    % setting any of these options triggers a status update

    function s = saveobj(obj)
        use_names = properties(obj);

        for i = 1:length(use_names)
            s.(use_names{i}) = obj.(use_names{i});
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

end

end

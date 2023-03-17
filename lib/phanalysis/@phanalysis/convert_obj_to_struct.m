function convert_obj_to_struct(OBJ)
%
%
%
%

use_names = properties(OBJ);

for i = 1:length(use_names)
    % need to keep the behavior object for distances...
    orig_warn = warning();
    warning off 'MATLAB:structOnObject'

    if isobject(OBJ.(use_names{i})) & ~isa(OBJ.(use_names{i}), 'kinect_model')

        for j = 1:length(OBJ.(use_names{i}))
            tmp(j) = struct(OBJ.(use_names{i})(j));
        end

        OBJ.(use_names{i}) = tmp;
        clear tmp;
    end

    warning(orig_warn);
end

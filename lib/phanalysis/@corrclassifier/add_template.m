function add_template(OBJ, TEMPLATE, CLASS)
%
%
%
%

if nargin < 3
    CLASS = '';
end

% templates are nsamples by class

[ndims ntemplates] = size(TEMPLATE);

if isempty(CLASS)
    CLASS = string([1:ntemplates]);
end

OBJ.classes = strcat(OBJ.classes, CLASS);

% make sure templates are formatted correctly...

if isempty(OBJ.templates)
    OBJ.templates = TEMPLATE;
elseif ndims == OBJ.ndims
    OBJ.templates(OBJ.nclasses + 1:OBJ.nclasses + ntemplates, :) = TEMPLATE;
else
    error('Template dimensionality %i does not match model dimensionality %i', ndims, OBJ.ndims);
end

OBJ.update_status;

function update_status(OBJ)
%
%
%

OBJ.ndims = size(OBJ.templates, 1);
OBJ.nclasses = size(OBJ.templates, 2);

if OBJ.nclasses ~= length(OBJ.classes)
    error('Number of templates %i not equal to number of classes %i', OBJ.nclasses, length(OBJ.classes));
end

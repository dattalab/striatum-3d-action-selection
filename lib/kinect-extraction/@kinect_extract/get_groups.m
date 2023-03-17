function GROUPS = get_groups(OBJ)
%
%
%
%

GROUPS = cell(size(OBJ));

for i = 1:length(OBJ)

    if isfield(OBJ(i).metadata, 'groups')
        GROUPS{i} = OBJ(i).metadata.groups;
    else
        GROUPS{i} = '';
    end

end

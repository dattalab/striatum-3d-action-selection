function IDX = filter_by_mouse(OBJ, MOUSE_IDX)
%
%
%

if isstring(MOUSE_IDX)
    MOUSE_IDX = {MOUSE_IDX{:}};
end

names = {OBJ(:).mouse_id};
IDX = false(size(names));

if iscell(MOUSE_IDX)

    for i = 1:length(MOUSE_IDX)
        IDX = IDX | strcmpi(names, MOUSE_IDX{i});
    end

else
    IDX = strcmpi(names, MOUSE_IDX);
end

function invert(OBJ)
%
%
%

for i = 1:length(OBJ)

    for j = 1:length(OBJ(i).traces)
        OBJ(i).traces(j).raw = -OBJ(i).traces(j).raw;
    end

    if ~isempty(OBJ(i).status)
        OBJ(i).status.invert = ~OBJ(i).status.invert;
    end

end

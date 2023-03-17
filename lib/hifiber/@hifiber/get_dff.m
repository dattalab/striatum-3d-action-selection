function get_dff(OBJ)
%
%
%

for i = 1:length(OBJ)

    for j = 1:length(OBJ(i).traces)

        if isfield(OBJ(i).traces(j), 'baseline')
            OBJ(i).traces(j).dff = (OBJ(i).traces(j).raw - OBJ(i).traces(j).baseline) ./ OBJ(i).traces(j).baseline;
        end

    end

end

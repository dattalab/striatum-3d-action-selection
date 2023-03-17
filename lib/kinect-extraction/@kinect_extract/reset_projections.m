function reset_projections(OBJ)
%
%
%

for i = 1:length(OBJ)
    to_delete = fieldnames(OBJ(i).projections);

    for j = 1:length(to_delete)

        if isfield(OBJ(i).projections, to_delete{j})
            OBJ(i).projections = rmfield(OBJ(i).projections, to_delete{j});
        end

    end

    OBJ(i).projections.pca = [];
    OBJ(i).projections.rp = [];
end

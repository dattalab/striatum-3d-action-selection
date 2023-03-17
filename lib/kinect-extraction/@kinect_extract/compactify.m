function compactify(OBJ, varargin)
%
%
%

for i = 1:length(varargin)

    switch lower(varargin{i})
        case 'rp'

            for j = 1:length(OBJ)
                OBJ(j).projections.rp = [];
            end

        case 'pca'

            for j = 1:length(OBJ)
                OBJ(j).projections.pca = [];
            end

        case 'tracking'

            for j = 1:length(OBJ)
                OBJ(j).tracking.centroid = []
                OBJ(j).tracking.orientation = [];
            end

    end

end

function load_projections(OBJ, KINECT, WHITEN_PCS)
%
%
%

if nargin < 3
    WHITEN_PCS = false;
end

use_scalars = {'centroid_x', 'centroid_y', 'angle', 'width', 'length', 'height_ave', ...
                 'velocity_mag', 'velocity_theta', 'area', 'velocity_mag_3d'};

ispca = false;

ispca = ~isempty(KINECT(1).projections.pca);

if ispca & WHITEN_PCS

    npcs = OBJ.options.npcs;
    mucov = nan(npcs, npcs, length(KINECT));

    for i = 1:length(KINECT)

        % demean, get covariance

        use_data = KINECT(i).projections.pca(:, 1:npcs);

        % remove nans

        use_data(any(isnan(use_data')), :) = [];
        use_data = bsxfun(@minus, use_data, mean(use_data));
        mucov(:, :, i) = cov(use_data, 1);

    end

    mucov = mean(mucov, 3);
    L = chol(mucov, 'lower');

end

for i = 1:length(KINECT)

    %map_time=KINECT(i).get_original_timebase;

    for j = 1:length(use_scalars)

        if isfield(KINECT(i).projections, use_scalars{j})
            OBJ.projections(i).scalars.(use_scalars{j}) = single(KINECT(i).projections.(use_scalars{j}));
        else
            OBJ.projections(i).scalars.(use_scalars{j}) = [];
        end

    end

    if isfield(KINECT(i).projections, 'changepoint_score')
        OBJ.projections(i).changepoint_score = single(KINECT(i).projections.changepoint_score);
    else
        OBJ.projections(i).changepoint_score = [];
    end

    if isfield(KINECT(i).projections, 'proj_idx')
        OBJ.projections(i).proj_idx = KINECT(i).projections.proj_idx;
        OBJ.metadata.time_mappers{i} = phanalysis.get_original_timebase(OBJ.projections(i).proj_idx, []);
    end

    if ~isempty(KINECT(i).projections.pca) & WHITEN_PCS

        use_data = KINECT(i).projections.pca(:, 1:10);

        new_data = nan(size(use_data));
        nan_idx = any(isnan(use_data'));
        use_data(nan_idx, :) = [];

        use_data = bsxfun(@minus, use_data, mean(use_data));
        use_data = linsolve(L, use_data')';
        new_data(~nan_idx, :) = use_data;

        OBJ.projections(i).pca = new_data;

    elseif ~isempty(KINECT(i).projections.pca)

        OBJ.projections(i).pca = KINECT(i).projections.pca(:, 1:10);

    end

end

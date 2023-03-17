function [BEST_PLANE] = plane_ransac(DEPTH_IMAGE, RANGE, ITERS, NOISE_TOLERANCE)
% Given a depth image, best plane fit
%
%

[height, width] = size(DEPTH_IMAGE);
[xx, yy] = meshgrid(1:width, 1:height);

use_points = find(DEPTH_IMAGE > RANGE(1) & DEPTH_IMAGE < RANGE(2));
npoints = numel(use_points);
use_points = [xx(use_points) yy(use_points) DEPTH_IMAGE(use_points(:))];

best_dist = inf;
best_num = 0;
in_ratio = .1;

upd = kinect_extract.proc_timer(ITERS, 'frequency', 20);

for i = 1:ITERS

    % get the triplet

    sel_idx = randperm(npoints, 3);

    % get the plane

    tmp_plane = plane_fit3(use_points(sel_idx, :));

    if isempty(tmp_plane)
        continue;
    end

    dist = abs(use_points * tmp_plane(1:3)' + tmp_plane(4));

    inliers = dist < NOISE_TOLERANCE;
    ninliers = sum(inliers);

    if (ninliers / npoints) > in_ratio && ninliers > best_num && mean(dist) < best_dist

        best_dist = mean(dist);
        best_num = ninliers;

        % new best model, use all inliers to perform the fit now

        use_data = use_points(inliers, :);
        MU = mean(use_data);
        [u s v] = svd(bsxfun(@minus, use_data, MU), 0);
        BEST_PLANE = [v(:, end)' -MU * v(:, end)];

    end

    upd(i);

end

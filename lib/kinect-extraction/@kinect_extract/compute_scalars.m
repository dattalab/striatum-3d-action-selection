function compute_scalars(OBJ)
%
%
%

OBJ.update_status;
opts = mergestruct(OBJ(1).options.common, OBJ(1).options.pca);

% let's switch everything over to memory mapping, everything else is ridiculous!

all_frames = OBJ.get_frame_total;
counter = 0;
edge_size = OBJ(1).options.common.box_size(1);
OBJ(1).pca.options = OBJ(1).options.pca;

timer_count = 0;

if isempty(OBJ(1).pca.coeffs) & OBJ(1).has_cable
    fprintf('Need to compute PC coefficients first, run get_pcs...\n');
    return;
end

if OBJ(1).options.pca.use_memmap & OBJ(1).has_cable
    status = OBJ.check_cat_file(true);

    if ~status
        error('Check the cat scratch file for errors...');
    end

end

for i = 1:length(OBJ)

    if isempty(OBJ(i).tracking) | (isempty(OBJ(i).tracking.centroid) | isempty(OBJ(i).tracking.orientation))
        fprintf('Loading tracking stats for object %i\n', i);
        OBJ(i).load_track_stats;
    end

end

fprintf('Computing scalars for all objects\n')
upd = kinect_extract.proc_timer(all_frames);

for i = 1:length(OBJ)

    % apply cable mask, iterate, dump scores

    nframes = OBJ(i).metadata.nframes;

    if isempty(OBJ(i).tracking)
        continue;
    end

    if isempty(OBJ(i).timestamps)
        OBJ(i).load_timestamps;
    end

    if OBJ(1).options.pca.use_memmap & OBJ(1).has_cable
        depth_bounded_rotated = reshape(OBJ(i).load_oriented_frames_cat_file(true), ...
            opts.box_size(1), opts.box_size(2), []);
    elseif OBJ(1).has_cable
        depth_bounded_rotated = OBJ(i).get_mouse_recon;
    else
        depth_bounded_rotated = OBJ(i).load_oriented_frames('raw', false, 'use_transform', true);
    end

    if ~isfield(OBJ(i).projections, 'proj_idx') | isempty(OBJ(i).projections.proj_idx)
        OBJ(i).get_uniform_timestamps(1 / opts.camera_fs + .01, opts.camera_fs);
    end

    proj_len = length(OBJ(i).projections.proj_idx);
    proj_idx = find(~isnan(OBJ(i).projections.proj_idx));

    OBJ(i).projections.centroid_x = nan(proj_len, 1);
    OBJ(i).projections.centroid_y = nan(proj_len, 1);
    OBJ(i).projections.angle = nan(proj_len, 1);

    OBJ(i).projections.angle(proj_idx) = OBJ(i).tracking.orientation / 180 * pi;
    OBJ(i).projections.centroid_x(proj_idx) = OBJ(i).tracking.centroid(:, 1);
    OBJ(i).projections.centroid_y(proj_idx) = OBJ(i).tracking.centroid(:, 2);

    OBJ(i).projections.width = nan(proj_len, 1);
    OBJ(i).projections.length = nan(proj_len, 1);
    OBJ(i).projections.height_ave = nan(proj_len, 1);
    OBJ(i).projections.velocity_mag = nan(proj_len, 1);
    OBJ(i).projections.velocity_mag_3d = nan(proj_len, 1);
    OBJ(i).projections.velocity_theta = nan(proj_len, 1);
    OBJ(i).projections.area = nan(proj_len, 1);

    mlength = nan(nframes, 1);
    width = nan(nframes, 1);
    marea = nan(nframes, 1);
    height_ave = nan(nframes, 1);

    parfor j = 1:nframes

        tmp = depth_bounded_rotated(:, :, j);
        tmp_mask = tmp > opts.height_floor & tmp < 200;
        [r, c] = find(tmp_mask);

        features = im_moment_features([c r], true);

        % OBJ(i).projections.width(proj_idx(j))=min(features.AxisLength);
        % OBJ(i).projections.length(proj_idx(j))=max(features.AxisLength);
        % OBJ(i).projections.area(proj_idx(j))=sum(tmp_mask(:));
        % OBJ(i).projections.height_ave(proj_idx(j))=mean(tmp(tmp_mask));

        width(j) = min(features.AxisLength);
        mlength(j) = max(features.AxisLength);
        marea(j) = sum(tmp_mask(:));
        height_ave(j) = mean(tmp(tmp_mask));

    end

    OBJ(i).projections.width(proj_idx) = width;
    OBJ(i).projections.length(proj_idx) = mlength;
    OBJ(i).projections.area(proj_idx) = marea;
    OBJ(i).projections.height_ave(proj_idx) = height_ave;

    vel_x = diff([OBJ(i).projections.centroid_x(1); OBJ(i).projections.centroid_x]);
    vel_y = diff([OBJ(i).projections.centroid_y(1); OBJ(i).projections.centroid_y]);
    vel_z = diff([OBJ(i).projections.height_ave(1); OBJ(i).projections.height_ave]);

    vel_angle = atan2(vel_y, vel_x);

    OBJ(i).projections.velocity_theta(proj_idx) = vel_angle(proj_idx);
    OBJ(i).projections.velocity_mag(proj_idx) = hypot(vel_x(proj_idx), vel_y(proj_idx));
    OBJ(i).projections.velocity_mag_3d(proj_idx) = sqrt(abs(vel_x(proj_idx)) .^ 2 + abs(vel_y(proj_idx)) .^ 2 + abs(vel_z(proj_idx)) .^ 2);

    counter = counter + OBJ(i).metadata.nframes;
    upd(counter);

end

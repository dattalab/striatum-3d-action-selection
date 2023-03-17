function track_stats(OBJ)
% Takes the tracked mouse and computes basic statistics for cropping and rotating.

if OBJ.status.track_stats
    fprintf('Tracking already complete.\n');
    return;
end

if (~OBJ.status.track & OBJ.use_tracking_model) | ...
        (~(OBJ.status.copy_frames & OBJ.status.remove_background & OBJ.status.apply_roi) & ~OBJ.status.use_tracking_model)
    fprintf('Object not ready for tracking.\n');
    return;
end

% read in defaults and tracking specific options

opts = mergestruct(OBJ.options.common, OBJ.options.stats);
opts_cell = map_parameters(opts);

% collect the movie

depth_memmap = matfile(OBJ.files.extract{1});
ismask = false;

if OBJ.use_tracking_model
    mask_memmap = matfile(OBJ.files.track{1});
    ismask = true;
end

% data is going in here

[height, width, nframes] = size(depth_memmap, opts.mem_var_stats);
steps = 0:OBJ.frame_stride:nframes;
steps = unique([steps nframes]);

% where the stats will go

depth_stats = cell(1, nframes);

fprintf('Computing tracking statistics...\n');
timer_upd = kinect_extract.proc_timer(length(steps) - 1);

for i = 1:length(steps) - 1

    left_edge = steps(i);
    right_edge = steps(i + 1);

    proc_frames = depth_memmap.(opts.mem_var_stats)(:, :, left_edge + 1:right_edge);

    if ismask
        proc_mask = mask_memmap.(opts.mem_var_stats_mask)(:, :, left_edge + 1:right_edge);
    else
        proc_mask = [];
    end

    proc_stats = im_stats(proc_frames, proc_mask, 'suppress_output', true, ...
        opts_cell{:});
    depth_stats(left_edge + 1:right_edge) = proc_stats;

    timer_upd(i);

end

clear proc_frames;
clear proc_mask;
clear depth_memmap;

depth_stats_fixed = depth_stats;

depth_stats_fixed = centroid_fix(depth_stats, 'smooth_span', opts.centroid_smoothing, ...
    'hampel_span', opts.centroid_hampel_span, 'hampel_sigma', opts.centroid_hampel_sigma);

if opts.weighted_centroid
    depth_stats_fixed = centroid_fix(depth_stats_fixed, 'smooth_span', opts.centroid_smoothing, ...
        'hampel_span', opts.centroid_hampel_span, 'hampel_sigma', opts.centroid_hampel_sigma, 'use_field', 'WeightedCentroid');
end

depth_stats_fixed = angle_fix(depth_stats_fixed, [], 'smooth_span', opts.angle_smoothing, ...
    'hampel_span', opts.angle_hampel_span, 'hampel_sigma', opts.angle_hampel_sigma);
depth_stats_fixed = ellipse_fix(depth_stats_fixed, 'smooth_span', opts.ellipse_smoothing, ...
    'hampel_span', opts.ellipse_hampel_span, 'hampel_sigma', opts.ellipse_hampel_sigma);

if opts.use_model
    likelihoods = zeros(1, nframes);

    for i = 1:nframes
        likelihoods(i) = sum(sum(mask_memmap.(opts.mem_var_stats_mask)(:, :, i)));
    end

    depth_stats_fixed = model_fix(depth_stats_fixed, likelihoods, ...
        'alpha_scale', opts.alpha_scale);
end

clear mask_memmap;

for i = 1:length(depth_stats)
    [depth_stats_fixed{i}.EllipseX, depth_stats_fixed{i}.EllipseY] = ...
        ellipse_fit(depth_stats_fixed{i}, opts.weighted_centroid);
end

% now we can ditch the cell array, move to struct, easier to stitch together later on...

% need to order fields lest we want things to be overwritten
% accidentally in the conversion to array of structures

for i = 1:length(depth_stats_fixed)
    tmp(i) = orderfields(depth_stats_fixed{i});
end

clear depth_stats_fixed;
depth_stats_fixed = tmp;
angles_fixed = false;

% no memmap necessary here...

fprintf('Saving results...\n');
save(fullfile(OBJ.working_dir, opts.proc_dir, opts.save_file), ...
    'depth_stats', 'depth_stats_fixed', 'angles_fixed', '-v7.3');

OBJ.update_status;

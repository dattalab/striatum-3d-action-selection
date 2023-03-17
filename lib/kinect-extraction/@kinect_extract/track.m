function track(OBJ)
% Uses a simple model to track the mouse in the presence of occluding objects.

if OBJ.status.track
    fprintf('Tracking already complete.\n');
    return;
end

if ~(OBJ.status.copy_frames & OBJ.status.remove_background & OBJ.status.apply_roi)
    fprintf('Object not ready for tracking.\n');
    return;
end

if ~OBJ.status.get_rois
    OBJ.load_rois;

    if ~OBJ.status.get_rois
        error('Need ROIs to continue, run get_rois');
    end

end

init_mu = [];
init_sig = [];

% read in defaults and tracking specific options

opts = mergestruct(OBJ.options.common, OBJ.options.track);
opts_cell = map_parameters(opts);

[pathname, filename, ext] = fileparts(OBJ.files.track{1});

% collect the movie

depth_memmap = matfile(OBJ.files.extract{1});

% load frame_stride frames at a time, remove cable, and save into another memmapped file
% data is going in here

save_memmap = matfile(OBJ.files.track{1});
save_memmap.Properties.Writable = true;
save_memmap.em_complete = false;

if matfile_check_flags(depth_memmap, 'frame_idx')
    fprintf('Copying frame indices...\n');
    OBJ.frame_indices = depth_memmap.frame_idx;
end

% steps

[height, width, nframes] = size(depth_memmap, 'depth_masked');
steps = 0:OBJ.frame_stride:nframes;
steps = unique([steps nframes]);
update_em = false;

% main loop

fprintf('Estimating tracking model...\n')

save_memmap = matfile_init_var(save_memmap, 'single', ...
    'depth_nocable_em_raw', [height width nframes], ...
    'depth_nocable_em_filt', [height width nframes]);
save_memmap = matfile_init_var(save_memmap, 'double', ...
    'depth_nocable_mu', [3 nframes], ...
    'depth_nocable_sig', [3 3 nframes]);

timer_upd = kinect_extract.proc_timer(length(steps) - 1);

for i = 1:length(steps) - 1

    left_edge = steps(i);
    right_edge = steps(i + 1);
    % step 1, remove as best we can through segmentation

    proc_frames = depth_memmap.depth_masked(:, :, left_edge + 1:right_edge);

    % em tracking, with a hootenany of parameters

    [proc_frames, proc_frames2, mu, sig, init_mask] = em_tracking(proc_frames, ...
        'suppress_output', true, 'init_mu', init_mu, 'init_sig', init_sig, 'init_mask', OBJ.rois.extraction, ...
        opts_cell{:});

    init_mu = mu(:, end);
    init_sig = sig(:, :, end);

    save_memmap.depth_nocable_em_raw(:, :, left_edge + 1:right_edge) = single(proc_frames);
    save_memmap.depth_nocable_em_filt(:, :, left_edge + 1:right_edge) = single(proc_frames2);
    save_memmap.depth_nocable_mu(:, left_edge + 1:right_edge) = mu;
    save_memmap.depth_nocable_sig(:, :, left_edge + 1:right_edge) = sig;

    timer_upd(i);

end

update_em = true;

clear proc_frames;
clear proc_frames2;
clear depth_memmap;

save_memmap.em_complete = true;
save_memmap.Properties.Writable = false;

OBJ.update_status;

function kinect_get_mouse_mask(OBJ, FORCE)
% Create a mask around the mouse (chopping off tail, e.g.).  Use this when you didn't use
% the tracking algorithm (i.e. no cable artifacts).

if nargin < 2
    FORCE = false;
end

OBJ.update_status;

if OBJ.status.get_mouse_mask & ~FORCE
    fprintf('Already created mouse mask...\n');
    return;
end

opts = mergestruct(OBJ.options.common, OBJ.options.mouse_mask);
opts_cell = map_parameters(opts);
mask_opts_cell = map_parameters(OBJ.options.mouse_mask);

save_memmap = matfile(OBJ.files.orient{1});
[height, width, nframes] = size(save_memmap, opts.mem_var);

if OBJ.status.orient & ~OBJ.has_cable
    save_memmap.Properties.Writable = true;
    save_memmap = matfile_init_var(save_memmap, 'uint8', 'depth_bounded_mouse_mask_rotated', [opts.box_size nframes]);
else
    fprintf('Improper object for mouse mask...\n');
    return;
end

save_memmap.frames_cleaned = false;

% steps

steps = 0:OBJ.frame_stride:nframes;
steps = unique([steps nframes]);

fprintf('Creating mask for mouse...\n');
upd = kinect_extract.proc_timer(length(steps) - 1);

for i = 1:length(steps) - 1

    left_edge = steps(i);
    right_edge = steps(i + 1);

    proc_frames = save_memmap.(opts.mem_var)(:, :, left_edge + 1:right_edge);

    % take the mouse with the loose crop and now recompute the stats and clean everything
    % up

    proc_mask = process_frame(proc_frames, mask_opts_cell{:}) > opts.open_threshold;

    if opts.use_cc
        proc_mask = kinect_extract.get_largest_blob(proc_mask);
    end

    save_memmap.depth_bounded_mouse_mask_rotated(:, :, left_edge + 1:right_edge) = uint8(proc_mask);

    upd(i);

end

save_memmap.frames_cleaned = true;
save_memmap.Properties.Writable = false;
clear proc_frames;
clear depth_memmap;

OBJ.update_status;

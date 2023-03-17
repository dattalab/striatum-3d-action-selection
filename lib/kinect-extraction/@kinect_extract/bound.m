function bound(OBJ)
% Crops the mouse from the raw data.

if OBJ.status.bound
    fprintf('Bounding already complete.\n');
    return;
end

if ~OBJ.status.track_stats
    fprintf('Object not ready for bounding.\n');
    return;
end

if isempty(OBJ.tracking)
    OBJ.load_track_stats;
end

opts = mergestruct(OBJ.options.common, OBJ.options.bound);
opts_cell = map_parameters(opts);

% collect the movie

depth_memmap = matfile(OBJ.files.extract{1});
[height, width, nframes] = size(depth_memmap, opts.mem_var);

% data is going in here

save_memmap = matfile(OBJ.files.bound{1});

varnames = whos(save_memmap);
varnames = {varnames(:).name};

save_memmap.Properties.Writable = true;
save_memmap.is_bounded = false;

% get class from the depth_memmap

tmp = whos(depth_memmap, opts.mem_var);
save_memmap = matfile_init_var(save_memmap, tmp.class, 'depth_bounded', [opts.box_size nframes]);

% load frame_stride frames at a time, remove cable, and save into another memmapped file

steps = 0:OBJ.frame_stride:nframes;
steps = unique([steps nframes]);

fprintf('Bounding mouse...\n');
timer_upd = kinect_extract.proc_timer(length(steps) - 1);

for i = 1:length(steps) - 1

    left_edge = steps(i);
    right_edge = steps(i + 1);

    proc_frames = depth_memmap.(opts.mem_var)(:, :, left_edge + 1:right_edge);

    proc_frames = bound_frames(proc_frames, ...
        OBJ.tracking.centroid(left_edge + 1:right_edge, :), ...
        'suppress_output', true, ...
        'box_size', opts.box_size);

    save_memmap.depth_bounded(:, :, left_edge + 1:right_edge) = proc_frames;

    timer_upd(i);

end

clear proc_frames;
clear depth_memmap;

save_memmap.is_bounded = true;
save_memmap.Properties.Writable = false;

OBJ.update_status;

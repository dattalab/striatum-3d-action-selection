function orient(OBJ, VAR)
% Reorients the bounded mouse data so that the mouse is facing the same direction
% (canonically, to the right).

if nargin < 2 | isempty(VAR)

    if OBJ.has_cable & OBJ.status.orient
        VAR = 'c';
    elseif OBJ.has_cable
        VAR = 'd';
    else
        VAR = 'd';
    end

end

switch lower(VAR(1))
    case 'd'
        mem_var = 'depth_bounded';
        rotate_mode = 1;
    case 'c'
        mem_var = 'depth_bounded_cable_mask';
        rotate_mode = 2;
end

if (rotate_mode == 1 & ~OBJ.status.bound) | ...
        (rotate_mode == 2 & ~OBJ.status.get_cable_mask)
    fprintf('Object not ready for orienting.\n');
    return;
end

if (rotate_mode == 1 & OBJ.status.orient) | ...
        (rotate_mode == 2 & OBJ.status.orient_cable_mask)
    fprintf('Object already oriented.\n');
    return;
end

if isempty(OBJ.tracking)
    OBJ.load_track_stats;
end

opts = mergestruct(OBJ.options.common, OBJ.options.orient);
opts_cell = map_parameters(opts);

% collect the movie

depth_memmap = matfile(OBJ.files.bound{1});
[height, width, nframes] = size(depth_memmap, mem_var);

% data is going in here

save_memmap = matfile(OBJ.files.orient{1});
save_var = [mem_var '_rotated'];
flag_var = [mem_var '_is_rotated'];

save_memmap.Properties.Writable = true;
save_memmap.(flag_var) = false;

% get class from the depth_memmap

tmp = whos(depth_memmap, mem_var);
save_memmap = matfile_init_var(save_memmap, tmp.class, save_var, [opts.box_size nframes]);

% load frame_stride frames at a time, remove cable, and save into another memmapped file

steps = 0:OBJ.frame_stride:nframes;
steps = unique([steps nframes]);

if rotate_mode == 1
    fprintf('Orienting mouse...\n');
else
    fprintf('Rotating mask...\n');
end

timer_upd = kinect_extract.proc_timer(length(steps) - 1);

for i = 1:length(steps) - 1

    left_edge = steps(i);
    right_edge = steps(i + 1);

    % the actual rotation function

    proc_frames = depth_memmap.(mem_var)(:, :, left_edge + 1:right_edge);
    proc_frames = rotate_frames(proc_frames, ...
        -OBJ.tracking.orientation(left_edge + 1:right_edge), ...
        'suppress_output', true);

    save_memmap.(save_var)(:, :, left_edge + 1:right_edge) = proc_frames;

    timer_upd(i);

end

clear proc_frames;
clear depth_memmap;
save_memmap.(flag_var) = true;
save_memmap.Properties.Writable = false;

OBJ.update_status;

function remove_background(OBJ)
% Removes the background from the data

if OBJ.status.remove_background
    fprintf('Background already removed\n');
    return;
end

fprintf('Removing background...\n');

opts_cell = map_parameters(OBJ.options.extract);
frame2_memmap = matfile(OBJ.files.extract{1});
frame2_memmap = bg_remove(frame2_memmap, 'mem_var', 'depth_masked', opts_cell{:}, ...
    'frame_stride', OBJ.frame_stride);
frame2_memmap.bg_removed = true;

OBJ.update_status;

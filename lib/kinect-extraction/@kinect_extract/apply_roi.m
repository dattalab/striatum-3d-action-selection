function apply_roi(OBJ)
% Applies ROI to data

if OBJ.status.apply_roi
    fprintf('Already applied ROI\n');
    return;
end

if ~OBJ.status.get_rois
    OBJ.load_rois;

    if ~OBJ.status.get_rois
        error('Need ROIs to continue, run get_rois');
    end

end

fprintf('Applying ROI...\n');
opts_cell = map_parameters(OBJ.options.extract);
frame2_memmap = matfile(OBJ.files.extract{1});
frame2_memmap = apply_mask(frame2_memmap, OBJ.rois.extraction, 'mem_var', 'depth_masked', opts_cell{:}, ...
    'frame_stride', OBJ.frame_stride);
frame2_memmap.is_masked = true;
frame2_memmap.Properties.Writable = false;

OBJ.update_status;

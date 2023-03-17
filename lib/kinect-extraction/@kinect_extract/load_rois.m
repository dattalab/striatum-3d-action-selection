function load_rois(OBJ)
% Loads in tracking and extraction rois for extraction
%

for i = 1:length(OBJ)

    if ~OBJ(i).files.roi{2}
        fprintf('No ROI file, run get_rois first\n');
        continue;
    end

    vars = who('-file', OBJ(i).files.roi{1});

    is_extraction = false;
    is_tracking = false;

    if any(strcmp(vars, 'extraction_roi'))
        load(OBJ(i).files.roi{1}, 'extraction_roi')
        OBJ(i).rois.extraction = extraction_roi;
        is_extraction = true;
    end

    if any(strcmp(vars, 'tracking_roi')) & OBJ(i).use_tracking_model
        load(OBJ(i).files.roi{1}, 'tracking_roi');
        OBJ(i).rois.tracking = tracking_roi;
        is_tracking = true;
    elseif OBJ(i).has_cable
        warning('No tracking ROI found, required for tracking with cable.');
    end

    if ~is_extraction & ~is_tracking & any(strcmp(vars, 'roi'))
        fprintf('Legacy format detected...\n');
        load(OBJ(i).files.roi{1}, 'roi');
        OBJ(i).rois.extraction = roi;
        extraction_roi = OBJ(i).rois.extraction;

        if exist(fullfile(OBJ(i).working_dir, OBJ(i).options.common.proc_dir, 'em_init_mask.mat'), 'file') == 2
            fprintf('Found legacy tracking roi...\n');
            load(fullfile(OBJ(i).working_dir, OBJ(i).options.common.proc_dir, 'em_init_mask.mat'), 'init_mask');
            OBJ(i).rois.tracking = init_mask
            tracking_roi = OBJ(i).rois.tracking;
            save(fullfile(OBJ(i).working_dir, 'roi.mat'), 'extraction_roi', 'tracking_roi');
        else
            save(fullfile(OBJ(i).working_dir, 'roi.mat'), 'extraction_roi');
        end

    end

    OBJ(i).update_status;

end

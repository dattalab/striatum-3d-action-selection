function update_status(OBJ)
% Updates the status of the object

OBJ.update_files;

for i = 1:length(OBJ)

    % if isempty(OBJ(i).working_dir)
    % 	continue;
    % end

    if ~OBJ(i).autoupdate
        continue;
    end

    OBJ(i).status = struct();

    if OBJ(i).use_tracking_model

        if isfield(OBJ(i).rois, 'extraction') & isfield(OBJ(i).rois, 'tracking')
            OBJ(i).status.get_rois = ~isempty(OBJ(i).rois.extraction) & ~isempty(OBJ(i).rois.tracking);
        else
            OBJ(i).status.get_rois = false;
        end

    else

        if isfield(OBJ(i).rois, 'extraction')
            OBJ(i).status.get_rois = ~isempty(OBJ(i).rois.extraction);
        else
            OBJ(i).status.get_rois = false;
        end

    end

    OBJ(i).status.copy_frames = matfile_check_flags(OBJ(i).files.extract{1}, 'frames_copied');
    OBJ(i).status.remove_background = matfile_check_flags(OBJ(i).files.extract{1}, 'bg_removed');
    OBJ(i).status.apply_roi = matfile_check_flags(OBJ(i).files.extract{1}, 'is_masked');
    OBJ(i).status.movies_extract = is_movie_file(fullfile(OBJ(i).working_dir, OBJ(i).options.common.proc_dir, 'depth_masked.*'));

    OBJ(i).status.track_stats = OBJ(i).files.track_stats{2};
    OBJ(i).status.movies_track_stats = is_movie_file(fullfile(OBJ(i).working_dir, OBJ(i).options.common.proc_dir, 'depth_stats.*'));

    OBJ(i).status.bound = matfile_check_flags(OBJ(i).files.bound{1}, 'is_bounded');
    OBJ(i).status.movies_bound = is_movie_file(fullfile(OBJ(i).working_dir, OBJ(i).options.common.proc_dir, 'depth_bounded.*'));

    OBJ(i).status.orient = matfile_check_flags(OBJ(i).files.orient{1}, 'depth_bounded_is_rotated');
    OBJ(i).status.movies_orient = is_movie_file(fullfile(OBJ(i).working_dir, OBJ(i).options.common.proc_dir, 'depth_bounded_rotated.*'));

    OBJ(i).status.get_cable_mask = matfile_check_flags(OBJ(i).files.bound{1}, 'frames_cleaned');
    OBJ(i).status.orient_cable_mask = matfile_check_flags(OBJ(i).files.orient{1}, 'depth_bounded_cable_mask_is_rotated');
    OBJ(i).status.get_mouse_mask = matfile_check_flags(OBJ(i).files.orient{1}, 'frames_cleaned');
    OBJ(i).status.orient_mouse_mask = matfile_check_flags(OBJ(i).files.orient{1}, 'depth_bounded_mouse_mask_is_rotated');

    if (OBJ(i).status.get_mouse_mask & OBJ(i).status.orient) & OBJ(i).has_cable
        OBJ(i).has_cable = false;
    end

    if (OBJ(i).status.get_cable_mask & OBJ(i).status.orient_cable_mask) & ~OBJ(i).has_cable
        OBJ(i).has_cable = true;
    end

    if OBJ(i).use_tracking_model
        OBJ(i).status.track = matfile_check_flags(OBJ(i).files.track{1}, 'em_complete');
        OBJ(i).status.movies_track = is_movie_file(fullfile(OBJ(i).working_dir, OBJ(i).options.common.proc_dir, 'depth_nocable_em*'));
    else
        OBJ(i).status.track = OBJ(i).files.track_stats{2};
    end

    if OBJ(i).status.track_stats
        is_flipped = load(OBJ(i).files.track_stats{1}, 'angles_fixed');

        if ((OBJ(i).has_cable & OBJ(i).status.orient & isfield(OBJ(i).status, 'orient_cable_mask') & OBJ(i).status.orient_cable_mask) ...
                | (~OBJ(i).has_cable)) & isfield(is_flipped, 'angles_fixed')
            OBJ(i).status.correct_flips = is_flipped.angles_fixed;
        else
            OBJ(i).status.correct_flips = false;
        end

    else
        OBJ(i).status.correct_flips = false;
    end

    if isa(OBJ(i).flip_model, 'CompactTreeBagger') | OBJ(i).files.flip_model{2}
        OBJ(i).status.flip_model = true;
    else
        OBJ(i).status.flip_model = false;
    end

    if OBJ(i).files.flip{2}
        OBJ(i).options.flip.method = 'f';
    end

    OBJ(i).status.write_movies = OBJ(i).status.movies_extract & OBJ(i).status.movies_track_stats ...
        & OBJ(i).status.movies_bound & OBJ(i).status.movies_orient;

    OBJ(i).status.projection_pca = ~isempty(OBJ(i).projections.pca);
    OBJ(i).status.projection_rp = ~isempty(OBJ(i).projections.rp);
    OBJ(i).status.changepoint_score = isfield(OBJ(i).projections, 'rp_changepoint_score');

    if isstruct(OBJ(i).behavior_model) & ~isempty(OBJ(i).behavior_model.labels) & isstruct(OBJ(i).behavior_model.parameters)
        OBJ(i).status.behavior_model = true;
    else
        OBJ(i).status.behavior_model = false;
    end

    OBJ(i).status.has_transform = ~isempty(OBJ(i).transform);
    OBJ(i).status.neural_photometry = isfield(OBJ(i).neural_data, 'photometry');

end

pc_status = false(size(OBJ));

for i = 1:length(OBJ)
    pc_status(i) = OBJ(i).pca.status.pcs_computed;
end

pc_idx = find(pc_status);

eq_flag = true;

for i = 1:length(pc_idx)

    for j = 1:length(pc_idx)

        if OBJ(pc_idx(i)).pca ~= OBJ(pc_idx(j)).pca
            warning('Objects %i and %i have different PCA objects', i, j)
        end

    end

end

for i = 1:length(OBJ)

    if eq_flag & any(pc_status)
        OBJ(i).status.pcs_exist = true;
    else
        OBJ(i).status.pcs_exist = false;
    end

end

if eq_flag & any(pc_status) & ~all(pc_status)
    fprintf('Copying PCs to objects...');
    cp_idx = find(~pc_status);
    use_idx = min(pc_idx);

    for i = 1:length(cp_idx)
        fprintf(' %i', i);
        OBJ(cp_idx).pca = OBJ(use_idx).pca;
    end

    fprintf(' success\n');
end

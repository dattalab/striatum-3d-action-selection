function [STEPS, FLAGS] = get_steps(OBJ)
%
%

if OBJ.use_tracking_model & OBJ.has_cable
    STEPS = {'get_rois', 'copy_frames', 'remove_background', 'apply_roi', 'track', ...
               'track_stats', 'bound', 'orient', 'get_cable_mask', 'orient', 'correct_flips', 'write_movies'};
    FLAGS = {'get_rois', 'copy_frames', 'remove_background', 'apply_roi', 'track', ...
               'track_stats', 'bound', 'orient', 'get_cable_mask', 'orient_cable_mask', 'correct_flips', 'write_movies'};
elseif OBJ.use_tracking_model
    STEPS = {'get_rois', 'copy_frames', 'remove_background', 'apply_roi', 'track', ...
               'track_stats', 'bound', 'orient', 'get_mouse_mask', 'correct_flips', 'write_movies'};
    FLAGS = {'get_rois', 'copy_frames', 'remove_background', 'apply_roi', 'track', ...
               'track_stats', 'bound', 'orient', 'get_mouse_mask', 'correct_flips', 'write_movies'};
else
    STEPS = {'get_rois', 'copy_frames', 'remove_background', 'apply_roi', ...
               'track_stats', 'bound', 'orient', 'get_mouse_mask', 'correct_flips', 'write_movies'};
    FLAGS = {'get_rois', 'copy_frames', 'remove_background', 'apply_roi', ...
               'track_stats', 'bound', 'orient', 'get_mouse_mask', 'correct_flips', 'write_movies'};
end

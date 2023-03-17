function [READY, MOVIES_DONE] = done_preprocessing(OBJ)
% Checks if preprocessing is complete

READY = false(size(OBJ));
MOVIES_DONE = false(size(OBJ));

for i = 1:length(OBJ)

    if OBJ(i).has_cable
        READY(i) = OBJ(i).status.get_cable_mask & OBJ(i).status.orient_cable_mask & OBJ(i).status.orient & OBJ(i).status.correct_flips;
    else
        READY(i) = OBJ(i).status.orient & OBJ(i).status.correct_flips & OBJ(i).status.get_mouse_mask;
    end

    MOVIES_DONE(i) = OBJ(i).status.write_movies;
end

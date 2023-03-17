function AVE = get_weighted_mouse_average(OBJ, ID)
%
%
%
%
%

% get average weighted by nframes

use_idx = find(OBJ.filter_by_mouse(ID));
AVE = zeros(OBJ(1).options.common.box_size);
all_frames = OBJ(use_idx).get_frame_total;

for i = use_idx
    AVE = AVE + (OBJ(i).metadata.nframes / all_frames) * OBJ(i).average_image;
end

function get_mouse_average(OBJ)
%
%

% sort by mouse IDs

tot_frames = get_frame_total(OBJ);
frame_count = 0;
timer_upd = kinect_extract.proc_timer(tot_frames);

for i = 1:length(OBJ)
    frames = OBJ(i).load_oriented_frames('raw', true, ...
        'use_transform', false, 'missing_value', 0);
    frames(frames < 5 | frames > 80) = nan;
    mu = nanmean(frames, 3);
    mu(isnan(mu)) = 0;
    OBJ(i).average_image = mu;
    frame_count = frame_count + OBJ(i).metadata.nframes;
    timer_upd(frame_count);
end

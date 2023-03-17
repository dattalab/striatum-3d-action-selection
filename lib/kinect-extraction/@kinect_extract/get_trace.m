function TRACE = get_trace(OBJ, ROI)
% just averages the pixels in a given roi, useful for simple stuff
%
%
%

fprintf('Applying ROI...\n');

frame2_memmap = matfile(OBJ.files.extract{1});
TRACE = zeros(OBJ.metadata.nframes, 1, 'int16');

roi_norm = sum(ROI(:));

steps = 0:OBJ.frame_stride:OBJ.metadata.nframes;
steps = unique([steps OBJ.metadata.nframes]);

timer_upd = kinect_extract.proc_timer(length(steps) - 1);

for i = 1:length(steps) - 1

    use_frames = length(steps(i) + 1:steps(i + 1));

    TRACE(steps(i) + 1:steps(i + 1)) = ...
        sum(sum(frame2_memmap.depth_masked(:, :, steps(i) + 1:steps(i + 1)) .* int16(repmat(ROI, [1 1 use_frames])))) ./ roi_norm;
    timer_upd(i);

end

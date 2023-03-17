function FRAMES = load_raw_frames(OBJ, FRAMES)
%
%
%
%

if length(FRAMES) > 1

    if all(diff(FRAMES)) ~= 1
        error('Frames must be continuous...');
    end

end

if OBJ.files.raw_data{2}
    frame_mmap = memmapfile(OBJ.files.raw_data{1}, 'format', 'uint16');

    nframes = length(frame_mmap.Data) / prod(OBJ.metadata.extract.DepthResolution);
    width = OBJ.metadata.extract.DepthResolution(1);
    height = OBJ.metadata.extract.DepthResolution(2);

    offset = (min(FRAMES) - 1) * (width * height);
    frame_width = range(FRAMES) + 1;
    frame_width
    % rotate the image and mirror flip
    offset
    FRAMES = int16(imrotate(reshape(frame_mmap.Data(offset + 1:offset + width * height * frame_width), [width height frame_width]), -90));

end

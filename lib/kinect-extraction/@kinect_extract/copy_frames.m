function copy_frames(OBJ)
% Extracts frames from the raw data saved by the acquisition software.

if OBJ.status.copy_frames
    fprintf('Already extracted raw frames\n');
    return;
end

opts = mergestruct(OBJ.options.common, OBJ.options.extract);

if ~exist(fullfile(OBJ.working_dir, opts.proc_dir), 'dir')
    fprintf('Creating processing directory...\n');
    mkdir(fullfile(OBJ.working_dir, opts.proc_dir));
end

if ~isfield(OBJ.metadata, 'extract')
    fprintf('Loading metadata...\n');
    OBJ.load_metadata;
end

frame2_memmap = matfile(fullfile(OBJ.files.extract{1}, 'depth_masked.mat'));

% collect the movie

%frame_mmap=memmapfile(OBJ.files.raw_data{1},'format','uint16');

% use metadata for the extaction

%nframes=length(frame_mmap.Data)/prod(OBJ.metadata.extract.DepthResolution);
filelisting = dir(OBJ.files.raw_data{1});

width = OBJ.metadata.extract.DepthResolution(1);
height = OBJ.metadata.extract.DepthResolution(2);
nframes = filelisting.bytes / (2 * width * height); % int16 = 2 bytes
frame2_memmap = matfile(fullfile(OBJ.files.extract{1}));
frame2_memmap.Properties.Writable = true;

frame2_memmap.bg_removed = false;
frame2_memmap.frames_copied = false;

frame2_memmap.depth_masked(height, width, nframes) = int16(0);

fprintf('Copying frame data...\n');

counter = 0;

steps = 0:OBJ.frame_stride:nframes;
steps = unique([steps nframes]);
fid = fopen(OBJ.files.raw_data{1}, 'rb');

timer_upd = kinect_extract.proc_timer(length(steps) - 1);

for i = 1:length(steps) - 1

    nframes_tmp = length(steps(i) + 1:steps(i + 1));
    npoints = height * width * nframes_tmp;
    frame2_memmap.depth_masked(:, :, steps(i) + 1:steps(i + 1)) = imrotate(reshape(fread(fid, npoints, '*int16'), [width height nframes_tmp]), -90);
    counter = counter + npoints;

    timer_upd(i);

end

fclose(fid);
frame2_memmap.frames_copied = true;
clear frame2_memmap;
OBJ.update_status;

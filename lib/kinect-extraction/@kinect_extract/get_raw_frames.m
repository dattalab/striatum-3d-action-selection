function RAW_FRAMES = get_raw_frames(OBJ, FRAME_IDX)
%
%

opts = mergestruct(OBJ.options.common, OBJ.options.extract);

if nargin < 2
    FRAME_IDX = [1 inf];
end

if ~OBJ.files.raw_data{2}
    warning('No raw data file, depth.dat found in working directory\n');
    return;
end

if ~isfield(OBJ.metadata, 'extract')
    fprintf('Loading metadata...\n');
    OBJ.load_metadata;
end

filelisting = dir(OBJ.files.raw_data{1});

width = OBJ.metadata.extract.DepthResolution(1);
height = OBJ.metadata.extract.DepthResolution(2);
nframes = filelisting.bytes / (2 * width * height); % int16 = 2 bytes

if FRAME_IDX(2) > nframes
    FRAME_IDX(2) = nframes;
end

if FRAME_IDX(1) < 1
    FRAME_IDX(1) = 1;
end

counter = 0;

fid = fopen(OBJ.files.raw_data{1}, 'rb');

nframes_tmp = length(FRAME_IDX(1):FRAME_IDX(2));
npoints = height * width * nframes_tmp;

% 2 bytes per int16, adjust offset accordingly

offset = height * width * (FRAME_IDX(1) - 1) * 2;
fseek(fid, offset, 'bof');

RAW_FRAMES = imrotate(reshape(fread(fid, npoints, '*int16'), [width height nframes_tmp]), -90);

fclose(fid);

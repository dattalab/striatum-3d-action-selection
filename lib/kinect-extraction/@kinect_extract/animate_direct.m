function animate_direct(FRAMES, varargin)
%
%
%
%
%
%

mask = [];
clim = 'auto';
fs = 30;
maxdots = 50;
eta_counter = 1;
eta_buffer = 50;
filename = 'data.mp4';
vid_stats = false;
mem_var = 'depth_data_masked';
stats = [];
marker_coords = [];
frame_stride = 400;
auto_frames = 1e3;
auto_per = [2.5 97.5];
auto_lims = [-100 100];
weighted_centroid = false;
scale = 'lin';
suppress_output = false;
vid_format = 'MPEG-4';
quality = 100;
cmap = bone(256);

nparams = length(varargin);

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

for i = 1:2:nparams

    switch lower(varargin{i})
        case 'cmap'
            cmap = varargin{i + 1};
        case 'mask'
            mask = varargin{i + 1};
        case 'clim'
            clim = varargin{i + 1};
        case 'filename'
            filename = varargin{i + 1};
        case 'fs'
            fs = varargin{i + 1};
        case 'stats'
            stats = varargin{i + 1};
        case 'mem_var'
            mem_var = varargin{i + 1};
        case 'marker_coords'
            marker_coords = varargin{i + 1};
        case 'auto_lims'
            auto_lims = varargin{i + 1};
        case 'auto_per'
            auto_per = varargin{i + 1};
        case 'auto_frames'
            auto_frames = varargin{i + 1};
        case 'weighted_centroid'
            weighted_centroid = varargin{i + 1};
        case 'frame_stride'
            frame_stride = varargin{i + 1};
        case 'scale'
            scale = varargin{i + 1};
        case 'suppress_output'
            suppress_output = varargin{i + 1};
        case 'vid_format'
            vid_format = varargin{i + 1};
        case 'quality'
            quality = varargin{i + 1};
        otherwise
    end

end

% need to check re: memmapfile here so we don't load everything into memory
ismemmap = false;

if strcmp(class(FRAMES), 'matlab.io.MatFile')
    [height, width, nframes] = size(FRAMES, mem_var);
    ismemmap = true;
else
    [height, width, nframes] = size(FRAMES);
end

if strcmp(clim, 'auto')

    % automatically determine climits

    if ismemmap
        tmp = FRAMES.(mem_var)(:, :, 1:min(nframes, auto_frames));
    else
        tmp = FRAMES(:, :, 1:min(nframes, auto_frames));
    end

    if strcmp(lower(scale(1:3)), 'log')
        tmp = log(tmp(tmp > 0));
    end

    clim = prctile(single(tmp(tmp > auto_lims(1) & tmp < auto_lims(2))), auto_per)';

end

is_ffmpeg = false;

if isunix & ~ismac

    fprintf('Linux environment detected, setting video format to Motion JPEG.\n');
    vid_format = 'Motion JPEG AVI';

    % check to see if we have ffmpeg on the commandline, hoo rah

    [exit_code, msg] = system('type ffmpeg');

    if exit_code == 0
        is_ffmpeg = true;
        fprintf('Found ffmpeg, will transcode and remove avi...\n');
    end

end

v = VideoWriter(filename, vid_format);
filename = fullfile(v.Path, v.Filename);
v.FrameRate = fs;
v.Quality = quality;

% if strcmp(lower(format),'motion jpeg avi')
% 	fprintf('Setting compression ratio to %i\n',10);
% 	v.CompressionRatio=10;
% end

open(v);

if frame_stride == inf
    frame_stride = nframes;
end

steps = 0:frame_stride:nframes;
steps = unique([steps nframes]);

timer_upd = kinect_extract.proc_timer(length(steps) - 1);

if ischar(cmap)
    cmap = colormap(cmap);
end

for i = 1:length(steps) - 1

    use_frames = length(steps(i) + 1:steps(i + 1));
    %writedata=zeros(height,width,3,use_frames,'single');
    % writedata=cell(1,use_frames);
    % writedata(:)={zeros(height,width,'single')};
    % cmap=cell(1,use_frames);
    % cmap(:)={jet(256)};

    for j = use_frames:-1:1
        f(j).colormap = cmap;
        f(j).cdata = zeros(height, width, 'single');
    end

    %writedata=zeros(height,width,use_frames,'single');

    if ismemmap
        proc_frames = double(FRAMES.(mem_var)(:, :, steps(i) + 1:steps(i + 1)));
    else
        proc_frames = double(FRAMES(:, :, steps(i) + 1:steps(i + 1)));
    end

    if strcmp(lower(scale(1:3)), 'log')
        proc_frames = log(proc_frames);
    end

    if mod(height, 2) ~= 0
        proc_frames = [proc_frames; zeros(1, width, use_frames)];
    end

    [height, width, ~] = size(proc_frames);

    if mod(width, 2) ~= 0
        proc_frames = [proc_frames zeros(height, 1, use_frames)];
    end

    if ~isempty(clim)
        proc_frames = proc_frames - clim(1);
        proc_frames(proc_frames < 0) = 0;
        proc_frames(proc_frames > (clim(2) - clim(1))) = clim(2) - clim(1);
        proc_frames = proc_frames ./ (clim(2) - clim(1));
    end

    % parfor here?

    for j = 1:use_frames

        tmp = proc_frames(:, :, j);
        [height, width] = size(tmp);
        %tmp=repmat(tmp,[1 1 3]);

        if ~isempty(stats)

            % throw in some stats on top of image

            if ~isempty(stats(steps(i) + j))

                coord_len = length(stats(steps(i) + j).EllipseX) * 2;
                coords = zeros(1, coord_len);
                coords(1:2:end) = stats(steps(i) + j).EllipseX;
                coords(2:2:end) = stats(steps(i) + j).EllipseY;

                %tmp=insertShape(tmp,'Polygon',coords,'Linewidth',1,'Color',[1 0 0]);
                tmp = rgb2gray(insertShape(tmp, 'Polygon', coords, 'Linewidth', 1));

                mask = zeros(size(tmp));

                if weighted_centroid
                    use_centroid = stats(steps(i) + j).WeightedCentroid;
                else
                    use_centroid = stats(steps(i) + j).Centroid;
                end

                if use_centroid(1) > width
                    use_centroid(1) = width;
                end

                if use_centroid(1) < 1
                    use_centroid(1) = 1;
                end

                if use_centroid(2) > height
                    use_centroid(2) = height;
                end

                if use_centroid(2) < 1
                    use_centroid(2) = 1;
                end

                %tmp=insertShape(tmp,'FilledCircle',[use_centroid(:)' 3],'Color',[1 0 1]);
                tmp = rgb2gray(insertShape(tmp, 'FilledCircle', [use_centroid(:)' 3]));

            end

            % maybe draw orientation too?

        end

        if ~isempty(marker_coords) & iscell(marker_coords) & ~isempty(marker_coords{j})
            marker_ind = sub2ind([height width], marker_coords{j}(:, 2), marker_coords{j}(:, 1));
            tmp(marker_ind) = 1;
        end

        f(j).cdata = round(tmp .* size(cmap, 1));

    end

    writeVideo(v, f);
    timer_upd(i);

end

%fprintf('\n');
close(v);

% the ffmpeg flag is only true if we have ffmpeg and we made an avi

if is_ffmpeg
    [pathname, file_split, ext] = fileparts(filename);
    new_filename = fullfile(pathname, [file_split '.mp4']);
    function_call = sprintf('ffmpeg -i "%s" -vcodec libx264 -crf 18 -threads 1 -preset veryfast -an "%s"', filename, new_filename)
    [exit_code, msg] = system(function_call)

    if exit_code == 0
        fprintf('Transcoding successful, removing avi file %s\n', filename);
        delete(filename);
    end

end

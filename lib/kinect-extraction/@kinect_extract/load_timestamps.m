function load_timestamps(OBJ, FORCE)
% Loads timestamps from text file saved by the Kinect 2 acquisition software
%

if nargin < 2 | isempty(FORCE)
    FORCE = false;
end

for i = 1:length(OBJ)

    delim = ' ';

    if OBJ(i).files.extract{2}
        depth_memmap = matfile(OBJ(i).files.extract{1});
    end

    if ~isempty(OBJ(i).timestamps) & ~FORCE
        fprintf('Timestamps already loaded...\n');
        continue;
    end

    if OBJ(i).files.depth_timestamps{2}
        fid = fopen(OBJ(i).files.depth_timestamps{1}, 'rt');

        % get number of cols

        line1 = fgets(fid);
        ncols = numel(strfind(line1, delim)) + 1;
        fclose(fid);
        fid = fopen(OBJ(i).files.depth_timestamps{1}, 'rt');

        if ncols == 2

            % TODO: add size specification here fool! [2 inf] for the third argument
            % and then transpose, this is a little silly

            tmp = fscanf(fid, '%f %f', [2 inf]);
            % OBJ(i).timestamps.depth=zeros(length(tmp)/2,2);
            % OBJ(i).timestamps.depth(:,1)=tmp(1:2:end)/1e3; % relative timestamps from the Kinect
            % OBJ(i).timestamps.depth(:,2)=tmp(2:2:end); % timestamps from the NI clock
            OBJ(i).timestamps.depth = tmp';
            OBJ(i).timestamps.depth(:, 1) = OBJ(i).timestamps.depth(:, 1) / 1e3;

        elseif ncols == 1
            tmp = fscanf(fid, '%f');
            OBJ(i).timestamps.depth = tmp(:);
        end

        fclose(fid);

        if OBJ(i).files.extract{2} & matfile_check_flags(depth_memmap, 'frame_idx')
            fprintf('Copying frame indices...\n');
            OBJ(i).timestamps.depth = OBJ(i).timestamps.depth(depth_memmap.frame_idx, :);
        end

        OBJ(i).metadata.nframes = size(OBJ(i).timestamps.depth, 1);

        camera_period = 1 / OBJ(i).options.common.camera_fs;

        tmp = floor(diff(OBJ(i).timestamps.depth(:, 1)) ./ camera_period) - 1;
        tmp(tmp < 0) = 0;
        OBJ(i).missing_frames = sum(tmp);

    end

    if OBJ(i).files.rgb_timestamps{2}
        fid = fopen(OBJ(i).files.rgb_timestamps{1}, 'rt');
        line1 = fgets(fid);
        ncols = numel(strfind(line1, delim)) + 1;
        fclose(fid);

        fid = fopen(OBJ(i).files.rgb_timestamps{1}, 'rt');

        if ncols == 2
            tmp = fscanf(fid, '%f %f');
            OBJ(i).timestamps.rgb = zeros(length(tmp) / 2, 2);
            OBJ(i).timestamps.rgb(:, 1) = tmp(1:2:end) / 1e3; % relative timestamps from the Kinect
            OBJ(i).timestamps.rgb(:, 2) = tmp(2:2:end); % timestamps from the NI clock
        elseif ncols == 1
            tmp = fscanf(fid, '%f');
            OBJ(i).timestamps.rgb = tmp(:);
        end

        fclose(fid);

        if matfile_check_flags(OBJ(i).files.extract{1}, 'frame_idx')
            fprintf('Copying frame indices...\n');
            OBJ(i).timestamps.rgb = OBJ(i).timestamps.rgb(depth_memmap.frame_idx, :);
        end

    end

    if isfield(OBJ(i).metadata, 'use_frames')

        if OBJ(i).files.depth_timestamps{2}
            OBJ(i).timestamps.depth = OBJ(i).timestamps.depth(OBJ(i).metadata.use_frames, :);
        end

        if OBJ(i).files.rgb_timestamps{2}
            OBJ(i).timestamps.rgb = OBJ(i).timestamps.rgb(OBJ(i).metadata.use_frames, :);
        end

        OBJ(i).metadata.nframes = size(OBJ(i).timestamps.depth, 1);

    end

    % TODO: use frame_idx to correct timestamps that we needed to strip...
    %
    % if matfile_check_flags(depth_memmap,'frame_idx')
    %   fprintf('Copying frame indices...\n');
    %   OBJ(i).frame_indices=depth_memmap.frame_idx;
    % end
end

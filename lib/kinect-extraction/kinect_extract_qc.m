function [MISSING_FRAMES, DUPE_FRAMES, TIMESTAMPS] = kinect_extract_qc(INPUT)
%
%
%
%

INPUTS = {};

if nargin < 1 | isempty(INPUT)
    [filename, pathname, ~] = uigetfile('*.tar.gz', 'Pick tarballs to check', 'MultiSelect', 'on');

    if iscell(filename)

        for i = 1:length(filename)
            INPUTS{i} = fullfile(pathname, filename{i});
        end

    elseif filename == 0
        return;
    else
        INPUTS{1} = fullfile(pathname, filename);
    end

else
    INPUTS{1} = INPUT;
end

% read the timestamps, make sure we're not missing a bunch

% is it a file, or a directory?

for i = 1:length(INPUTS)

    fprintf('Processing %s...\n', INPUTS{i})
    fprintf('Extracting the depth timestamps...\n');

    % so MATLAB's untar sucks
    %untar(TO_EXT,fullfile(pathname,basename));

    if isunix
        [path, file, ext] = fileparts(INPUTS{i});
        [status, msg] = system(sprintf('tar -zvxf %s depth_ts.txt', INPUTS{i}));
    else
        [status, msg] = system(['"C:\Program Files\WinRAR\WinRar.exe" e -o+ ' INPUTS{i} ' depth_ts.txt']);
    end

    if status == 0
        fprintf('success\n');
    else
        fprintf('failed\n');
        fprintf('%s\n', msg);
        return;
    end

    fid = fopen('depth_ts.txt', 'rt');

    % get number of cols

    delim = ' ';

    % TODO: update the size specification for reading in timestamps
    % e.g. [2 inf] then transpose

    line1 = fgets(fid);
    ncols = numel(strfind(line1, delim)) + 1;
    frewind(fid);

    if ncols == 2
        fprintf('Found 2 columns in timestamp file...\n');
        tmp = fscanf(fid, '%f %f', [2 inf]);
        % TIMESTAMPS=zeros(length(tmp)/2,2);
        % TIMESTAMPS(:,1)=tmp(1:2:end)/1e3; % relative timestamps from the Kinect
        % TIMESTAMPS(:,2)=tmp(2:2:end); % timestamps from the NI clock
        TIMESTAMPS = tmp';
    elseif ncols == 1
        fprintf('Found 1 column in timestamp file...\n');
        tmp = fscanf(fid, '%f');
        TIMESTAMPS = tmp(:);
    else
        error('Did not understand timestamp file...');
    end

    fclose(fid);

    camera_period = 1/30;

    % missing frames is number of periods between timestamps more than 1

    tmp_df = floor(diff(TIMESTAMPS(:, 1)) ./ camera_period) - 1;
    tmp_df(tmp_df < 0) = 0;
    total = numel(TIMESTAMPS(:, 1));
    MISSING_FRAMES = sum(tmp_df);

    fprintf('Found %i/%i missing frame(s)\n', MISSING_FRAMES, total);

    DUPE_FRAMES = sum(diff(TIMESTAMPS(:, 1)) == 0);

    fprintf('Found %i/%i duplicate frame(s)\n', DUPE_FRAMES, total);

    miss_frac = MISSING_FRAMES / total;
    dupe_frac = DUPE_FRAMES / total;
    warnings = 0;

    if miss_frac > .01
        warning('%g percent frames missing, SOMETHING IS LIKELY WRONG', miss_frac * 1e2);
        warnings = warnings + 1;
    end

    if dupe_frac > .01
        warning('%g percent frames are duplicates, SOMETHING IS LIKELY WRONG', dupe_frac * 1e2);
        warnings = warnings + 1;
    end

    fprintf('Found %i warnings\n', warnings);

    if warnings == 0
        fprintf('Everything checks out...\n');
    end

end

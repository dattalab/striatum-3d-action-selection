function kinect_extract_it(TO_EXT, HAS_CABLE, POOL, BATCH_PROCESSOR, NTHREADS)
%kinect_extract_it - Orchestrates the extraction of a data file or directory
%results are saved to the sub directory proc.  Searches for flip detectors, named
%flip*.mat, and options, named *.config in the current directory,
%and up to two directories up.
%
% Usage: kinect_extract_it(to_ext,has_cable,pool,batch_processor,nthreads)
%
% Inputs:
%   to_ext (string): data file or directory to extract (*.tar.gz or directory with depth.dat)
%   has_cable (bool): whether data has cables present or not (default: false)
%   pool (int): if non-empty will open a parpool with this many workers (default: [])
%   batch_processor (string): where to send jobs (default: 'local')
%   nthreads (int): if non-empty, set number of computational threads per worker (default: [])
%
% Examples:
%   cd ~/dir_with_tarball
%   kinect_extract_it('tarball.tar.gz',true)
%
% See also: kinect_extract_findall_objects, kinect_extract_get_all_projections

if nargin < 5 | isempty(NTHREADS)
    NTHREADS = [];
end

if nargin < 4 | isempty(BATCH_PROCESSOR)
    BATCH_PROCESSOR = 'local';
end

if nargin < 3 | isempty(POOL)
    POOL = [];
end

if nargin < 2 | isempty(HAS_CABLE)
    HAS_CABLE = false;
end

% do the frontend stuff, check if it's a directory or a tarball, process accordingly
if ~isempty(NTHREADS) & isnumeric(NTHREADS) & NTHREADS > 0
    fprintf('Setting number of threads to %i\n', NTHREADS);
    nthreads = maxNumCompThreads(NTHREADS);
    fprintf('Current number of threads:  %i\n', nthreads);
end

if ~isempty(POOL) & isnumeric(POOL) & POOL > 0
    fprintf('Setting pool size to %i\n', POOL);
    p = parpool('local', POOL);
    p.IdleTimeout = inf;
    fprintf('Current pool size %i\n', p.NumWorkers);
end

fprintf('Detected ');

if ~isdir(TO_EXT)
    [pathname, filename, ext] = fileparts(TO_EXT);

    if strcmp([filename ext], 'depth.dat')
        TO_EXT = pathname;
    end

end

is_directory = false;

if isdir(TO_EXT)

    if TO_EXT(end) == filesep
        TO_EXT = TO_EXT(1:end - 1);
    end

    is_directory = true;
    fprintf('directory %s...extracting\n', TO_EXT);
elseif ~isempty(regexp(TO_EXT, '.*.tar.gz$'))
    fprintf('tarball %s\n...untarring to ', TO_EXT);
    tokens = regexp(TO_EXT, filesep, 'split');
    [pathname, filename, ext] = fileparts(TO_EXT);
    basename = regexprep(tokens{end}, '.tar.gz$', '');
    untar_path = fullfile(pathname, basename);
    fprintf('"%s"...', untar_path);

    if exist(untar_path, 'dir')
        error('Directory %s already exists', untar_path)
    else
        mkdir(untar_path);
    end

    [status, msg] = system(sprintf('tar -xzvf "%s" -C "%s"', TO_EXT, untar_path));
    % so MATLAB's untar sucks
    %untar(TO_EXT,fullfile(pathname,basename));
    if status == 0
        fprintf('success\n');
    else
        fprintf('failed\n');
        fprintf('%s\n', msg);
        return;
    end

    TO_EXT = fullfile(pathname, basename);
end

% check for options and flip models one directory up (or two?)

ext = kinect_extract(TO_EXT);

% loop through directories starting at root

tokens = regexp(TO_EXT, filesep, 'split');

if is_directory
    pathname = TO_EXT;
end

if isempty(pathname)
    pathname = '.';
end

max_depth = 4;

for i = max_depth:-1:1
    parent_dir = pathname;

    for j = 1:i - 1
        parent_dir = fullfile(parent_dir, '..');
    end

    if ~isdir(parent_dir)
        continue;
    end

    flip_file = fullfile(parent_dir, 'flip*.mat');
    options_file = fullfile(parent_dir, '*.config');

    flip_files = dir(flip_file);
    options_files = dir(options_file);

    if ~isempty(flip_files)
        flip_file = fullfile(parent_dir, flip_files(1).name);
        fprintf('Using flip file %s\n', flip_file);
        ext.flip_model = flip_file;
    end

    if ~isempty(options_files)
        options_file = fullfile(parent_dir, options_files(1).name);
        fprintf('Using options file %s\n', options_file);
        ext.set_options_from_file(options_file);
    end

end

if ~HAS_CABLE
    fprintf('No cable, turning off cable tracking...\n');
    ext.has_cable = false;
    ext.use_tracking_model = false;
end

fprintf('Using batch process %s\n', BATCH_PROCESSOR);
ext.submit_batch_job(BATCH_PROCESSOR);

% submit the batch job, bookmark ensures we don't clobber anything in progress

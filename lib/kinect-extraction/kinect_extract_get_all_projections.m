function kinect_extract_get_all_projections(PROC, NWORKERS, CLUSTER_PROFILE)
%kinect_extract_get_all_projections - Orchestrates computing projections for kinect_extractions
%results will be saved to model objects and _analysis/kinect_pca.mat
%
% Usage: kinect_extract_get_all_projections(proc,nworkers,cluster_profile)
%
% Inputs:
%   proc (string, or kinect_extract object): either objects to process or directory with extractions
%   nworkers (int): number of workers for job (default: 19)
%   cluster_profile (string): cluster profile to open parpool on (default: 'local')
%
% Example:
%   cd ~/dir_with_lots_of_extractions
%   kinect_extract_get_all_projections(pwd,5,'local');
%
% See also: kinect_extract_findall_objects, kinect_extract_get_all_projections

if nargin < 3
    CLUSTER_PROFILE = 'local';
end

if nargin < 2
    NWORKERS = 19;
end

p = parpool(CLUSTER_PROFILE, NWORKERS);
p.IdleTimeout = inf;

if isa(PROC, 'kinect_extract')
    fprintf('Processing object array with %i objects\n', length(PROC));
    OBJ_ARRAY = PROC;
elseif isdir(PROC)
    fprintf('Processing directory %s\n', PROC);
    fprintf('Loading objects in directory...\n');

    cd(PROC);

    OBJ_ARRAY = kinect_extract_findall_objects([], true);
    OBJ_ARRAY.use_defaults;

    options_file = fullfile(PROC, '*.config');
    options_files = dir(options_file);

    if ~isempty(options_files)
        options_file = fullfile(PROC, options_files(1).name);
        fprintf('Using options file %s\n', options_file);
        OBJ_ARRAY.set_options_from_file(options_file);
    end

else
    error('Did not understand input (must be a directory or object array)')
end

fprintf('Reseting PCs and projections...');

OBJ_ARRAY.reset_pcs;
OBJ_ARRAY.reset_projections;

fprintf('success\n');

OBJ_ARRAY.compute_all_projections;
OBJ_ARRAY.save_progress;

fprintf('Exporting PCA for modeling...');

OBJ_ARRAY.export_projection_to_cell('pca');

fprintf('success\n');

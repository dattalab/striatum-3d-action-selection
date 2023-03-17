function CELL = export_projection_to_cell(OBJ, NAME, SUFFIX)
%export_projection_to_cell- Exports projection from object or object array to a .mat file
%results are stored in _analysis/export_SUFFIX.mat
%
% Usage: obj.export_projection_to_cell(name,suffix)
%
% Inputs:
%   name (string): field from obj.projections to export to mat file (default: 'pca')
%   suffix (string): string to append to file (default: '')
%
% Example:
%   cd ~/dir_with_lots_of_extractions
%   kinect_objects=kinect_extract_findall_objects; % get the objects
%   kinect_objects.compute_all_projections; % compute all projections, including pca, rps
%   kinect_objects.export_projection_to_cell('pca','firstattempt') % export pca to MATLAB file
%
% See also: kinect_extract_findall_objects, kinect_extract_get_all_projections

if nargin < 3
    SUFFIX = '';
end

if nargin < 2 | isempty(NAME)
    NAME = 'pca';
end

CELL = cell(1, length(OBJ));
UUIDS = cell(1, length(OBJ));

for i = 1:length(OBJ)
    CELL{i} = OBJ(i).projections.(NAME);
    UUIDS{i} = OBJ(i).metadata.uuid;
end

if isfield(OBJ(1).metadata, 'groups')
    GROUP = cell(1, length(OBJ));

    for i = 1:length(OBJ)
        GROUP{i} = OBJ(i).metadata.groups;
    end

else
    GROUP = {};
end

save_fun = @(features, uuids, groups) save(fullfile(OBJ(1).options.common.analysis_dir, sprintf('export_%s%s.mat', NAME, SUFFIX)), ...
    'features', 'uuids', 'groups', '-v7.3');
save_fun(CELL, UUIDS, GROUP);

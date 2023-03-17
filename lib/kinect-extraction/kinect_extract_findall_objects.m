function [OBJ, NEW_OBJ] = kinect_extract_findall_objects(DIR, FIND_NEW, AUTOUPDATE, varargin)
%kinect_extract_finall_objects- Collects all kinect_extract objects in a given directory
%returns an object or object array of kinect_extract objects.
%
% Usage: kinect_extract_findall_objects(dir,find_new,autoupdate,varargin)
%
% Inputs:
%   dir (string): directory to recursively check for kinect_extract objects (default: pwd)
%   find_new (bool): create new objects in data directories with no object, i.e. kinect_object.mat (default:false)
%   autoupdate (bool): on loading, update all fields of the object (default: true)
%   varargin (strings): set field to empty on loading to conserve memory, e.g. 'rps' (default: none)
%
% Example:
%   cd ~/dir_with_lots_of_extractions
%   kinect_objects=kinect_extract_findall_objects(pwd,true,'rps','pca') % load all objects, empty rps and pca to save RAM
%
% See also: kinect_extract_findall_objects, kinect_extract_get_all_projections

OBJ = kinect_extract.empty;
NEW_OBJ = kinect_extract.empty;

if nargin < 3 | isempty(AUTOUPDATE)
    AUTOUPDATE = true;
end

if nargin < 2 | isempty(FIND_NEW)
    FIND_NEW = false;
end

if nargin < 1 | isempty(DIR)
    DIR = pwd;
end

tmp = kinect_extract.dir_recurse(DIR, 'kinect_object.mat');
warning('off', 'MATLAB:load:classNotFound');

if length(tmp) > 0

    found_pca = false;

    load(tmp(1).name, 'extract_object');

    if ~isempty(varargin)
        extract_object.compactify(varargin{:});
    end

    OBJ(1) = extract_object;
    tmp2 = kinect_extract.dir_recurse(extract_object.options.common.analysis_dir, 'kinect_pca.mat');
    tmp3 = kinect_extract.dir_recurse(pwd, 'kinect_pca.mat');

    if length(tmp2) > 0
        fprintf('Found pca object file %s, will load\n', tmp2(1).name);
        load(tmp2(1).name, 'pca_object');
        found_pca = true;
        OBJ(1).pca = pca_object;
    elseif length(tmp3) > 0
        fprintf('Found pca object file %s, will load\n', tmp3(1).name);
        load(tmp3(1).name, 'pca_object');
        found_pca = true;
        OBJ(1).pca = pca_object;
    end

    upd = kinect_extract.proc_timer(length(tmp) - 1);

    for i = 2:length(tmp)

        load(tmp(i).name, 'extract_object')

        if found_pca
            extract_object.pca = pca_object;
        end

        if ~isempty(varargin)
            extract_object.compactify(varargin{:});
        end

        OBJ(i) = extract_object;
        upd(i - 1);

    end

    upd(inf);

end

if FIND_NEW
    NEW_OBJ = kinect_extract_findall(DIR, true);
end

if isempty(OBJ) & ~isempty(NEW_OBJ)
    OBJ = NEW_OBJ;
elseif ~isempty(NEW_OBJ)

    for i = 1:length(NEW_OBJ)
        OBJ(end + 1) = NEW_OBJ(i);

        if found_pca
            OBJ(end).pca = pca_object;
        end

    end

end

if ~isempty(OBJ)
    OBJ.set_autoupdate(AUTOUPDATE);
    OBJ.update_files;
    OBJ.update_status;
end

warning('on', 'MATLAB:load:classNotFound');

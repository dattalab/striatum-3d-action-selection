function OBJ = kinect_extract_findall(DIR, NEW_ONLY)
% This function runs all preprocessing steps necessary to track the mouse and
% clean up any cable-related artifacts.  The same algorithm can be used for
% data without cables as well.
%

% get all depth data files in the current root

OBJ = kinect_extract.empty;

if nargin < 2
    NEW_ONLY = false;
end

config_filter(1).field = 'config';
config_filter(1).filename = '.*.config$';
config_filter(1).multi = 0;

config_filter(2).field = 'skip';
config_filter(2).filename = 'skip';
config_filter(2).multi = 0;

config_filter(3).field = 'roi';
config_filter(3).filename = 'roi.mat';
config_filter(3).multi = 0;

config_filter(4).field = 'flip_detector';
config_filter(4).filename = 'flip_detector.mat';
config_filter(4).multi = 0;

if nargin < 1 | isempty(DIR)
    DIR = pwd;
end

idx = 0;
tmp = kinect_extract.dir_recurse(DIR, 'depth.dat', [], [], config_filter);
listing = {};
names = {};

if ~isempty(tmp)
    listing{end + 1} = tmp;
    names{end + 1} = {listing{end}(:).name};
    names{end} = regexprep(names{end}, '/depth.dat', '');
end

proc_files = {'depth_masked.mat', 'depth_stats.mat', 'depth_bounded.mat', 'depth_bounded_rotated.mat'};

for i = 1:length(proc_files)
    tmp = kinect_extract.dir_recurse(DIR, proc_files{i}, [], [], config_filter);

    if ~isempty(tmp)
        listing{end + 1} = tmp;
        names{end + 1} = {listing{end}(:).name};
        names{end} = regexprep(names{end}, sprintf('/proc/%s', proc_files{i}), '');
    end

end

listing = cat(2, listing{:});
names = cat(2, names{:});
to_del = false(size(names));

if NEW_ONLY

    for i = 1:length(names)

        if exist(fullfile(names{i}, 'kinect_object.mat'), 'file') || ~isempty(listing(i).skip)
            to_del(i) = true;
        end

    end

end

listing = listing(~to_del);
names = names(~to_del);

[uniq, ia, ib] = unique(names);

listing = listing(ia);
names = names(ia);

% PROCESS in order of files!

detectors = {listing(:).flip_detector};
[uniq_detectors, ~, detector_idx] = unique(detectors);
to_load = find(cellfun(@(x) ~isempty(x), uniq_detectors));

for i = length(listing):-1:1
    OBJ(i) = kinect_extract(names{i});
end

for i = 1:length(to_load)

    model_idx = find(detector_idx == to_load(i));

    for j = 1:length(model_idx)
        fprintf('Assigning flip model %s to %s\n', uniq_detectors{to_load(i)}, OBJ(model_idx(j)).working_dir);
        OBJ(model_idx(j)).flip_model = uniq_detectors{to_load(i)};
    end

end

for i = 1:length(listing)

    if ~isempty(listing(i).roi)
        %OBJ(i).files.roi{1}=listing(i).roi{1};
        OBJ(i).set_file('roi', listing(i).roi);
        OBJ(i).update_files;
    end

    if ~isempty(listing(i).config)
        fprintf('Assigning options from %s to %s\n', listing(i).config, OBJ(i).working_dir);
        OBJ(i).set_options_from_file(listing(i).config);
    end

end

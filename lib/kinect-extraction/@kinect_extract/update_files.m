function update_files(OBJ)
% Updates the filenames using the working_dir property

for i = 1:length(OBJ)

    % if isempty(OBJ(i).working_dir)
    %   continue;
    % end

    files = struct();

    files.extract = fullfile(OBJ(i).working_dir, OBJ(i).options.common.proc_dir, 'depth_masked.mat');
    files.bound = fullfile(OBJ(i).working_dir, OBJ(i).options.common.proc_dir, 'depth_bounded.mat');
    files.orient = fullfile(OBJ(i).working_dir, OBJ(i).options.common.proc_dir, 'depth_bounded_rotated.mat');
    files.track_stats = fullfile(OBJ(i).working_dir, OBJ(i).options.common.proc_dir, 'depth_stats.mat');
    files.track = fullfile(OBJ(i).working_dir, OBJ(i).options.common.proc_dir, 'depth_nocable_em.mat');
    files.photometry = fullfile(OBJ(i).working_dir, OBJ(i).options.common.proc_dir, 'photometry.mat');
    files.raw_data = fullfile(OBJ(i).working_dir, 'depth.dat');
    files.roi = fullfile(OBJ(i).working_dir, 'roi.mat');
    files.metadata = fullfile(OBJ(i).working_dir, 'metadata.json');
    files.depth_timestamps = fullfile(OBJ(i).working_dir, 'depth_ts.txt');
    files.rgb_timestamps = fullfile(OBJ(i).working_dir, 'rgb_ts.txt');
    files.nidaq = fullfile(OBJ(i).working_dir, 'nidaq.dat');
    files.skip = fullfile(OBJ(i).working_dir, 'skip');
    files.use_frames = fullfile(OBJ(i).working_dir, OBJ(i).options.common.proc_dir, 'use_frames.mat');
    files.frame_idx = fullfile(OBJ(i).working_dir, OBJ(i).options.common.proc_dir, 'frame_idx.mat');
    files.flip = fullfile(OBJ(i).working_dir, OBJ(i).options.common.proc_dir, 'flips.txt');
    files.flip_model = fullfile(OBJ(i).working_dir, 'flip_detector.mat');
    files.cat_frames = fullfile(OBJ(i).options.common.analysis_dir, 'cat_frames.mat');
    files.cat_frames_scratch = fullfile(OBJ(1).options.common.analysis_dir, 'cat_frames_scratch.mat');

    tdt_chk = dir(fullfile(OBJ(i).working_dir, 'tdt*.dat'));
    ca_chk = dir(fullfile(OBJ(i).working_dir, 'recording*results*.mat'));

    % new cnmf-e output files to check

    ca_chk_new = {'cnmfe*.mat', 'neuron-extract*.mat', 'motion*results.mat'};

    if length(tdt_chk) > 0
        %files.tdt_data={};
        for j = 1:length(tdt_chk)
            files.(sprintf('tdt_data_%03i', j)) = fullfile(OBJ(i).working_dir, tdt_chk(j).name);
        end

    else
        files.tdt_data = fullfile(OBJ(i).working_dir, 'tdt.dat');
    end

    if length(ca_chk) > 0
        files.ca_data = fullfile(OBJ(i).working_dir, ca_chk(1).name);
    else
        files.ca_data = fullfile(OBJ(i).working_dir, 'cadata.dat');
    end

    for j = 1:length(ca_chk_new)
        tmp = dir(fullfile(OBJ(i).working_dir, ca_chk_new{j}));

        if length(tmp) > 0
            files.ca_data_new = fullfile(OBJ(i).working_dir, tmp(1).name);
        end

    end

    if ~isfield(files, 'ca_data_new')
        files.ca_data_new = fullfile(OBJ(i).working_dir, 'cadata.dat');
    end

    filenames = fieldnames(files);

    for j = 1:length(filenames)

        % first need a check to see if it exists

        if isfield(OBJ(i).files, filenames{j})
            OBJ(i).files.(filenames{j}){2} = exist(OBJ(i).files.(filenames{j}){1}, 'file') == 2;
        end

        if ~isfield(OBJ(i).files, filenames{j})
            OBJ(i).files.(filenames{j}){1} = files.(filenames{j});
        elseif ~strcmp(OBJ(i).files.(filenames{j}){1}, files.(filenames{j})) & exist(files.(filenames{j}), 'file')
            OBJ(i).files.(filenames{j}){1} = files.(filenames{j});
        elseif isempty(OBJ(i).files.(filenames{j}){1}) | ~OBJ(i).files.(filenames{j}){2}
            OBJ(i).files.(filenames{j}){1} = files.(filenames{j});
        end

        OBJ(i).files.(filenames{j}){2} = exist(OBJ(i).files.(filenames{j}){1}, 'file') == 2;

    end

    obj_filenames = fieldnames(OBJ(i).files);

    for j = 1:length(obj_filenames)

        if ~any(strcmp(obj_filenames{j}, filenames))
            OBJ(i).files = rmfield(OBJ(i).files, obj_filenames{j});
        end

    end

end

function compute_pcs(OBJ)
% compute pcs, decide on whether to use iterative cable cleanup or not
%
%

% loop over objects
% how to pick directory for analysis??

OBJ.update_status;

% if ~exist(fullfile(pwd,'analysis'),'dir')
%   mkdir(fullfile(pwd,'analysis'));
% end

% timestamps........

OBJ(1).pca.options = OBJ(1).options.pca;

% don't need em if we don't have a cable

if ~OBJ(1).has_cable
    fprintf('No cable present, setting PCA iterations to 1\n');
    OBJ(1).pca.options.max_iters = 1;
end

OBJ(1).pca.missing_data = OBJ(1).has_cable;
OBJ(1).pca.frame_stride = OBJ(1).options.pca.chunk_size;

% remove data not ready for pca

OBJ(~OBJ.done_preprocessing) = [];
scratch_file = 'cat_frames_scratch.mat';

if ~OBJ(1).status.pcs_exist

    if OBJ(1).options.pca.use_memmap

        fprintf('Will use memory mapping...\n');

        if OBJ(1).files.cat_frames{2}

            [status, map, to_add] = OBJ.check_cat_file;
            all_data = matfile(OBJ(1).files.cat_frames{1});

            if status & all_data.copy_complete
                fprintf('Found valid cat file, will not reload frames...\n');
            elseif ~isempty(to_add) & ~all(isnan(status)) & all_data.copy_complete
                fprintf('Cat file is valid, but objects ')
                add_idx = find(isnan(map));

                for i = 1:length(add_idx)
                    fprintf(' %i', add_idx(i));
                end

                fprintf(' will be added first...\n')
                OBJ(isnan(map)).append_cat_file;
                [status, map, to_add] = OBJ.check_cat_file;
                all_data = matfile(OBJ(1).files.cat_frames{1});

                if status & all_data.copy_complete
                    fprintf('Success! continuing\n')
                else
                    fprintf('failed, bailing\n');
                    return;
                end

            else
                fprintf('There is an issue with the cat file, delete %s and retry...\n', OBJ(1).files.cat_file{1});
                %OBJ.load_oriented_frames_cat_memmap(false,true);
                return;
            end

        else

            fprintf('No cat file present, creating one...\n');

            if ~isfield(OBJ(1).options.pca, 'use_mask') | ~OBJ(1).options.pca.use_mask
                fprintf('Will not use a mask...\n');
                tmp = false;
            else
                fprintf('Will use a mask...\n');
                tmp = true;
            end

            OBJ.make_cat_file('raw', false, 'use_transform', true, 'use_mask', OBJ(1).options.pca.use_mask);

        end

        % copy to an unvarnished file and work with the scratch file
        % only copy to scratch if we have missing data (otherwise we're not doing any reconstruction)

        OBJ.update_files;
        [pathname, filename, ext] = fileparts(OBJ(1).files.cat_frames{1});

        fprintf('Copying to scratch file...');
        status = copyfile(fullfile(pathname, [filename ext]), fullfile(pathname, scratch_file));

        if status
            fprintf('success\n');
        else
            fprintf('failed, bailing\n')
            return;
        end

        all_data = matfile(fullfile(pathname, scratch_file));
        fprintf('Will use %s frames to compute PCs...\n', size(all_data, 'cat_frames', 2));
        OBJ(1).pca.compute_coeffs_memmap(all_data);
        clear all_data;

    else
        all_data = OBJ.load_oriented_frames_cat('max_frames', OBJ(1).options.pca.max_frames, ...
            'raw', false, 'use_transform', true);
        all_data = reshape(all_data, size(all_data, 1) ^ 2, []);
        OBJ(1).pca.compute_coeffs(all_data);
    end

    % keep track of what scores belong to which file...

else
    fprintf('Found PCs in at least one object in the array, run reset_pcs to clear them...\n');
    return;
end

for i = 2:length(OBJ)
    OBJ(i).pca = OBJ(1).pca;
end

OBJ.update_status;

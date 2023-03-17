function save_progress(OBJ)
%
%
%

savefun = @(save_path, hifiber_object) save(save_path, 'hifiber_object', '-v7.3');

if ~exist(OBJ.options.save_dir, 'dir')
    mkdir(OBJ.options.save_dir);
end

savefun(fullfile(OBJ.options.save_dir, 'hifiber_object.mat'), OBJ);

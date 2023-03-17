function save_progress(OBJ, FNAME)
%
%
%
%

savefun = @(save_path, phanalysis_object) save(save_path, 'phanalysis_object', '-v7.3');

if ~exist(OBJ.options.save_dir, 'dir')
    mkdir(OBJ.options.save_dir);
end

if isempty(FNAME)
    FNAME = 'phanalysis_object';
end

savefun(fullfile(OBJ.options.save_dir, FNAME), OBJ);

function save_progress(OBJ, FORCE_PCA, AGG)
%
%
%
%

if nargin < 3
    AGG = false;
end

if nargin < 3
    FORCE_PCA = false;
end

% store the pca object

pca_obj = OBJ(1).pca.copy;
OBJ.reset_pcs;

if AGG

    if ~exist(fullfile(pwd, OBJ(1).options.common.analysis_dir), 'dir')
        mkdir(fullfile(pwd, OBJ(1).options.common.analysis_dir));
    end

    extract_object = OBJ;
    save(fullfile(pwd, OBJ(1).options.common.analysis_dir, 'kinect_object.mat'), 'extract_object', '-v7.3');
else

    savefun_pca = @(save_path, pca_object) save(save_path, 'pca_object');
    savefun = @(save_path, extract_object) save(save_path, 'extract_object');

    fprintf('Saving PCA...\n')

    if ~isempty(pca_obj.coeffs) | FORCE_PCA
        savefun_pca(fullfile(OBJ(1).options.common.analysis_dir, 'kinect_pca.mat'), pca_obj);
    else
        fprintf('PCA object is empty, set FORCE_PCA to true if you want to overwrite\n');
    end

    fprintf('Saving all kinect objects...\n');

    upd = kinect_extract.proc_timer(length(OBJ));

    for i = 1:length(OBJ)
        savefun(fullfile(OBJ(i).working_dir, 'kinect_object.mat'), OBJ(i));
        upd(i);
    end

end

for i = 1:length(OBJ)
    OBJ(i).pca = pca_obj;
end

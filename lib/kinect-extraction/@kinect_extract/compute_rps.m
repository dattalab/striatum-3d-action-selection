function get_projection_rp(OBJ)
% check for pca object, apply to each file and store in extract object

OBJ.update_status;
opts = mergestruct(OBJ(1).options.common, OBJ(1).options.pca);

if isempty(OBJ(1).pca.coeffs) & OBJ(1).has_cable
    fprintf('Need to compute PC coefficients first, run get_pcs...\n');
    return;
end

if OBJ(1).options.pca.use_memmap & OBJ(1).has_cable

    for i = 1:length(OBJ)

        if ~OBJ(i).files.cat_frames_scratch{2}
            fprintf('Invalid scratch file for object %i\n', i);
            return
        end

    end

end

all_frames = OBJ.get_frame_total;
upd = kinect_extract.proc_timer(all_frames);
timer_count = 0;

% number of dimensions to use defined by the jl-lemma
% http://scikit-learn.org/stable/modules/generated/sklearn.random_projection.johnson_lindenstrauss_min_dim.html#sklearn.random_projection.johnson_lindenstrauss_min_dim

nframes = OBJ.get_frame_total;
ncomponents = round(4 * log(nframes) / (opts.jl_eps ^ 2/2 - opts.jl_eps ^ 3/3));
nanzscore = @(x) bsxfun(@rdivide, bsxfun(@minus, x, nanmean(x)), nanstd(x));

if OBJ(1).options.pca.use_memmap
    status = OBJ.check_cat_file(true);

    if ~status
        error('Check the cat scratch file for errors...');
    end

end

for i = 1:length(OBJ)

    % if using missing data reconstruct the data using the cutoff pcs

    if OBJ(1).options.pca.use_memmap & OBJ(1).has_cable

        features = single(OBJ(i).load_oriented_frames_cat_file(true));
        OBJ(i).projections.rp = nan(numel(OBJ(i).projections.proj_idx), ncomponents);
        place_vec = ~isnan(OBJ(i).projections.proj_idx);
        OBJ(i).projections.rp(place_vec, :) = gaussproj(features', ncomponents);
        OBJ(i).projections.rp = single(nanzscore(nanzscore(OBJ(i).projections.rp)')');

    elseif OBJ(1).has_cable

        use_pcs = OBJ(i).projections.pca(:, 1:opts.cut_recon);
        idx = 1:size(use_pcs, 1);
        features = OBJ(i).pca.coeffs(:, 1:opts.cut_recon) * use_pcs';
        OBJ(i).projections.rp = gaussproj(features', ncomponents);
        OBJ(i).projections.rp = single(nanzscore(nanzscore(OBJ(i).projections.rp)')');

    else

        features = single(OBJ(i).load_oriented_frames);
        features = reshape(features, 80 ^ 2, []);
        OBJ(i).projections.rp = gaussproj(features', ncomponents);
        OBJ(i).projections.rp = single(nanzscore(nanzscore(OBJ(i).projections.rp)')');

    end

    timer_count = timer_count + OBJ(i).metadata.nframes;
    upd(timer_count);

end

OBJ.update_status;

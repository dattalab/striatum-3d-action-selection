function plot_aligned_data(OBJ, NORMALIZE)
%
%
%
%

if nargin < 2
    NORMALIZE = 'z';
end

% plot the spines (use reconstruction if it has a cable)

if ~OBJ.status.projection_rp
    fprintf('Need rps, run get_projection_rp...\n');
    return;
end

% if ~OBJ.status.changepoint_score
% 	fprintf('Need changepoint score, run get_changepoint_score...\n');
% 	return;
% end

if OBJ.status.neural_photometry
    nplots = 4;
else
    nplots = 3;
end

if OBJ.has_cable

    use_pcs = OBJ.projections.pca_smooth(:, 1:OBJ.options.pca.cut_recon);
    idx = 1:size(use_pcs, 1);

    for j = 1:OBJ.options.pca.cut_recon
        nans = isnan(use_pcs(:, j));
        use_pcs(nans, j) = interp1(idx(~nans), use_pcs(~nans, j), idx(nans), 'spline');
    end

    recon = OBJ.pca.coeffs(:, 1:OBJ.options.pca.cut_recon) * use_pcs';
    depth_bounded_rotated = reshape(recon, OBJ.options.common.box_size(1), OBJ.options.common.box_size(2), []);

else

    % just load in the frames and project them dude

    depth_bounded_rotated = OBJ.load_oriented_frames;

end

tvec = OBJ.timestamps.depth(:, 2);
tvec = tvec - min(tvec);

ax(1) = subplot(nplots, 1, 1);
imagesc(tvec, [], squeeze(mean(depth_bounded_rotated(30:40, :, :))));
set(ax(1), 'XTick', []);
colormap(ax(1), bone);
caxis([10 60]);

ax(2) = subplot(nplots, 1, 2);
imagesc(tvec, [], OBJ.get_original_timebase(OBJ.projections.rp)');
set(ax(2), 'XTick');
colormap(ax(2), bone);
caxis([-3 3]);

ax(3) = subplot(nplots, 1, 3);
%plot(tvec,OBJ.get_original_timebase(OBJ.projections.rp_changepoint_score));
labels = OBJ.behavior_model.labels(:)';
imagesc(tvec, [], labels);
colormap(ax(3), distinguishable_colors(length(unique(labels))));
axis off;
%set(ax(3),'YDir','rev');

if OBJ.status.neural_photometry

    ax(4) = subplot(nplots, 1, 4);

    traces_to_plot = cat(2, OBJ.neural_data.photometry.traces(:).dff);

    if strcmp(lower(NORMALIZE(1)), 'n')

        % add appropriate spacing between traces, scale bars, etc.

    else

        plot(tvec, zscore(traces_to_plot));

    end

end

linkaxes(ax, 'x');

% scale bar on final axis

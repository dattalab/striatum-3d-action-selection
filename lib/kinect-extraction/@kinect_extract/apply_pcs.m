function apply_pcs(OBJ)
% check for pca object, apply to each file and store in extract object

OBJ.update_status;
opts = mergestruct(OBJ(1).options.common, OBJ(1).options.pca);

if isempty(OBJ(1).pca.coeffs)
    fprintf('Need to compute PC coefficients first, run get_pcs...\n');
    return;
end

if ~OBJ(1).has_cable
    opts.iters = 1;
    missing_data = false;
else
    missing_data = true;
end

% let's switch everything over to memory mapping, everything else is ridiculous!

all_frames = OBJ.get_frame_total;

upd = kinect_extract.proc_timer(all_frames);
edge_size = OBJ(1).options.common.box_size(1);
OBJ(1).pca.options = OBJ(1).options.pca;

timer_count = 0;

if OBJ(1).options.pca.use_memmap
    status = OBJ.check_cat_file(true);

    if ~status
        error('Check the cat scratch file for errors...');
    end

end

for i = 1:length(OBJ)

    % apply cable mask, iterate, dump scores

    nframes = OBJ(i).metadata.nframes;

    if isempty(OBJ(i).timestamps)
        OBJ(i).load_timestamps;
    end

    if OBJ(1).options.pca.use_memmap

        depth_bounded_rotated = single(OBJ(i).load_oriented_frames_cat_file(true));

        if OBJ(1).options.pca.use_fft
            depth_bounded_rotated = abs(fft2(reshape(depth_bounded_rotated, edge_size, edge_size, [])));
            depth_bounded_rotated = reshape(depth_bounded_rotated, edge_size ^ 2, []);
        end

    else

        if missing_data
            depth_bounded_rotated = OBJ(i).get_mouse_recon;
        else
            [depth_bounded_rotated, missing_value] = OBJ(i).load_oriented_frames('raw', false, 'use_transform', true);
        end

        if OBJ(1).options.pca.use_fft
            depth_bounded_rotated = abs(ff2(depth_bounded_rotated));
        end

        depth_bounded_rotated = reshape(depth_bounded_rotated, edge_size ^ 2, []);
        depth_bounded_rotated = single(depth_bounded_rotated);

    end

    cur_scores = OBJ(1).pca.coeffs(:, 1:opts.score_cut)' * ...
        bsxfun(@minus, depth_bounded_rotated, mean(depth_bounded_rotated));

    % use the final iteration for the scores we'll keep

    [corrected_timestamps, corrected_idx, corrected_vec] = ...
        OBJ(i).get_uniform_timestamps(1 / opts.camera_fs + .01, opts.camera_fs);

    corrected_scores = nan(size(cur_scores, 1), numel(corrected_timestamps));
    corrected_scores(:, corrected_vec) = cur_scores;

    % find correlated changes, simply add up discrete deriv. across dims

    if opts.sigma_t > 0
        tmp = nanmean(diff(corrected_scores')' .^ 2);
        tmp = [0 tmp];
        idx = tmp > (nanmean(tmp) + opts.sigma_t * nanstd(tmp));
        tau_samples = round(opts.camera_fs * opts.sigma_tau);
        idx = conv(double(idx), ones(tau_samples, 1) / tau_samples, 'same');
        idx = (idx > opts.sigma_thresh) | (corrected_scores(1, :) == 0);
        corrected_scores(:, idx) = nan;
    end

    % clean up time series w/ interpolation, unless we're too far from a good frame

    corrected_scores = kinect_extract.clean_up_timeseries(corrected_scores');
    nans = isnan(corrected_scores(:, 1));

    if ~isempty(opts.bandpass) & length(opts.bandpass) == 2
        [b, a] = ellip(5, .2, 40, [opts.bandpass] / (opts.camera_fs / 2), 'bandpass');
        filt_scores = corrected_scores;
        filt_scores(nans, :) = 0;
        filt_scores = filtfilt(b, a, filt_scores);
        filt_scores(nans, :) = nan;
        corrected_scores = filt_scores;
    end

    OBJ(i).projections.pca = corrected_scores;

    % save which timestamps were inserted so we can get the original timebase later

    % this is done in get_uniform timestamps now
    % OBJ(i).projections.proj_idx=nan(numel(corrected_timestamps),1);
    % OBJ(i).projections.proj_idx(corrected_vec)=1:size(cur_scores,2);

    if opts.score_smooth > 0

        OBJ(i).projections.pca_smooth = zeros(size(OBJ(i).projections.pca));

        for j = 1:size(OBJ(i).projections.pca, 2)

            % hampel filter for outliers, then smooth (medfilt1 instead?)

            tmp = hampel(OBJ(i).projections.pca(:, j), opts.hampel_span, opts.hampel_sigma);

            % repeated median filtering (are we sure about this and not a simpler smoothing kernel?)

            switch lower(opts.score_smooth_method(1))
                case 'm'

                    for k = 1:length(opts.score_smooth)
                        OBJ(i).projections.pca_smooth(:, j) = medfilt1(tmp, opts.score_smooth(k), 'omitnan');
                    end

                case 'g'

                    % for either convolution, pad with repeating values

                    h = normpdf(-5 * opts.score_smooth:5 * opts.score_smooth, 0, opts.score_smooth);
                    OBJ(i).projections.pca_smooth(:, j) = phanalysis.padded_conv(tmp, h, 'r');

                case 'b'

                    h = ones(opts.score_smooth, 1) / opts.score_smooth;
                    OBJ(i).projections.pca_smooth(:, j) = phanalysis.padded_conv(tmp, h, 'r');

                otherwise

                    OBJ(i).projections.pca_smooth(:, j) = tmp;

            end

            OBJ(i).projections.pca_smooth(nans, j) = nan;

        end

    end

    timer_count = timer_count + OBJ(i).metadata.nframes;
    upd(timer_count);

end

OBJ.update_status;

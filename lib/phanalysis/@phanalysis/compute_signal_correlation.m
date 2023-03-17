function compute_signal_correlation(OBJ)
%
%
%
%

OBJ.stats.signal_corr = struct();
counter = 1;
upd = kinect_extract.proc_timer(length(OBJ.photometry));
nanzscore = @(x) (x - nanmean(x)) ./ nanstd(x);

for i = 1:length(OBJ.photometry)

    if OBJ.session(i).has_photometry & OBJ.session(i).use_gcamp & OBJ.session(i).use_rcamp

        % normalize the two traces, get signal correlation

        norm_rcamp = nanzscore(OBJ.normalize_trace(OBJ.photometry(i).traces(4).dff));
        norm_gcamp = nanzscore(OBJ.normalize_trace(OBJ.photometry(i).traces(1).dff));

        use_ts = ~isnan(norm_rcamp) & ~isnan(norm_gcamp);
        OBJ.stats.signal_corr(counter).cross_raw = xcorr(norm_rcamp(use_ts), norm_gcamp(use_ts), OBJ.options.max_lag, 'coeff');

        % get peaks for correlogram and autocorrelogram

        [~, gcamp_peaks] = findpeaks(norm_gcamp, 'minpeakheight', 1.5, 'minpeakdistance', 5);
        [~, rcamp_peaks] = findpeaks(norm_rcamp, 'minpeakheight', 1.5, 'minpeakdistance', 5);

        gcamp_bin = zeros(size(norm_gcamp));
        gcamp_bin(gcamp_peaks) = 1;
        gcamp_bin = gcamp_bin - mean(gcamp_bin);
        rcamp_bin = zeros(size(norm_rcamp));
        rcamp_bin(rcamp_peaks) = 1;
        rcamp_bin = rcamp_bin - mean(rcamp_bin);

        OBJ.stats.signal_corr(counter).cross_bin = xcorr(rcamp_bin, gcamp_bin, OBJ.options.max_lag, 'coeff');
        OBJ.stats.signal_corr(counter).auto_gcamp_bin = xcorr(gcamp_bin, gcamp_bin, OBJ.options.max_lag, 'coeff');
        OBJ.stats.signal_corr(counter).auto_rcamp_bin = xcorr(rcamp_bin, rcamp_bin, OBJ.options.max_lag, 'coeff');

        norm_rcamp = nanzscore(OBJ.normalize_trace(OBJ.photometry(i).traces(4).dff, true));
        norm_gcamp = nanzscore(OBJ.normalize_trace(OBJ.photometry(i).traces(1).dff, true));

        use_ts = ~isnan(norm_rcamp) & ~isnan(norm_gcamp);
        OBJ.stats.signal_corr(counter).cross_raw_dt = xcorr(norm_rcamp(use_ts), norm_gcamp(use_ts), OBJ.options.max_lag, 'coeff');

        % get peaks for correlogram and autocorrelogram

        [~, gcamp_peaks] = findpeaks(norm_gcamp, 'minpeakheight', 1.5, 'minpeakdistance', 5);
        [~, rcamp_peaks] = findpeaks(norm_rcamp, 'minpeakheight', 1.5, 'minpeakdistance', 5);

        gcamp_bin = zeros(size(norm_gcamp));
        gcamp_bin(gcamp_peaks) = 1;
        gcamp_bin = gcamp_bin - mean(gcamp_bin);
        rcamp_bin = zeros(size(norm_rcamp));
        rcamp_bin(rcamp_peaks) = 1;
        rcamp_bin = rcamp_bin - mean(rcamp_bin);

        OBJ.stats.signal_corr(counter).cross_bin_dt = xcorr(rcamp_bin, gcamp_bin, OBJ.options.max_lag, 'coeff');
        OBJ.stats.signal_corr(counter).auto_gcamp_bin_dt = xcorr(gcamp_bin, gcamp_bin, OBJ.options.max_lag, 'coeff');
        OBJ.stats.signal_corr(counter).auto_rcamp_bin_dt = xcorr(rcamp_bin, rcamp_bin, OBJ.options.max_lag, 'coeff');

        counter = counter + 1;
    end

    upd(i);

end

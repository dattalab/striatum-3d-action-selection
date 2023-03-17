function TRACE = normalize_trace(OBJ, TRACE, USE_DELTAS, DECONVOLVE_FILTER)
%
%
%

if nargin < 4
    DECONVOLVE_FILTER = [];
end

if nargin < 3 | isempty(USE_DELTAS)
    USE_DELTAS = false;
end

if isvector(TRACE)
    TRACE = TRACE(:);
end

% use method specified in options, blah blah blah

nans = isnan(TRACE);

if OBJ.options.filter_trace & ~isempty(OBJ.options.filter_corners)

    switch lower(OBJ.options.filter_method)
        case 'but'
            %[smooth_b,smooth_a]=butter(3,[OBJ.options.filter_corners]/(OBJ.options.fs/2),OBJ.options.filter_type);
            [smooth_b, smooth_a] = butter(3, [OBJ.options.filter_corners] / (OBJ.options.fs / 2), OBJ.options.filter_type);
            TRACE(nans) = 0;
            TRACE = filtfilt(smooth_b, smooth_a, TRACE);
            TRACE(nans) = nan;
        case 'ellip'
            [smooth_b, smooth_a] = ellip(2, .2, 40, [OBJ.options.filter_corners] / (OBJ.options.fs / 2), OBJ.options.filter_type);
            TRACE(nans) = 0;
            TRACE = filtfilt(smooth_b, smooth_a, TRACE);
            TRACE(nans) = nan;
        case 'kaiser'
            [n, Wn, beta, ftype] = kaiserord([OBJ.options.filter_corners], [0 1], [.1 .05], OBJ.options.fs);
            smooth_b = fir1(n, Wn, ftype, kaiser(n + 1, beta), 'noscale');
            smooth_a = 1;
        case 'exp'
            smps = round(OBJ.options.filter_corners(1) * OBJ.options.fs);
            kernel_t = 1:6 * smps;
            kernel = exp(-kernel_t / smps);
            kernel = kernel ./ sum(kernel);

            for i = 1:size(TRACE, 2)
                new_trace = conv(TRACE(:, i), kernel, 'full');
                TRACE(:, i) = new_trace(1:length(TRACE(:, i)));
            end

        otherwise
    end

end

if ~isempty(DECONVOLVE_FILTER)
    % inverse filter, don't get fancy!
    TRACE(nans) = 0;
    sig_len = numel(TRACE);
    fft_sig = fft(TRACE, sig_len);
    fft_filt = fft(DECONVOLVE_FILTER(:), sig_len);
    fft_quot = fft_sig ./ (fft_filt + .5);
    TRACE = real(ifft(fft_quot));
    TRACE(nans) = nan;
end

if (USE_DELTAS | OBJ.options.use_deltas) & OBJ.options.rectify
    TRACE = phanalysis.compute_deltas(TRACE', OBJ.options.deltas_win)';
    TRACE(TRACE < 0) = 0;
elseif (USE_DELTAS | OBJ.options.use_deltas)
    TRACE = phanalysis.compute_deltas(TRACE', OBJ.options.deltas_win)';
end

if ~isempty(OBJ.options.normalize_method)

    switch lower(OBJ.options.normalize_method)

        case 'z'

            TRACE = phanalysis.nanzscore(TRACE);

        case 'mz'

            TRACE = phanalysis.nanzscore(TRACE, true);

        case 'h'

        case 'nc'

            TRACE = normc(TRACE);

        case 'nr'

            TRACE = normr(TRACE);

        case 'm'

            TRACE = (TRACE - prctile(TRACE, 2.5)) ./ (prctile(TRACE, 97.5) - prctile(TRACE, 2.5));

    end

end

if ~isempty(OBJ.options.binarize) & strcmp(lower(OBJ.options.binarize(1)), 'r')

    thresh = nanmean(TRACE) + OBJ.options.binarize_sigma_t * nanstd(TRACE);
    idx = 1:size(TRACE, 1) - 1;
    bin = false(size(TRACE, 1) - 1, size(TRACE, 2));

    for i = 1:size(TRACE, 2)
        bin(:, i) = TRACE(idx, i) < thresh(i) & TRACE(idx + 1, i) >= thresh(i);
    end

    bin = [false(1, size(bin, 2)); bin];

    smps = round(OBJ.options.fs .* OBJ.options.binarize_smooth);
    mov_ave = ones(smps, 1) / smps;

    for i = 1:size(TRACE, 2)
        TRACE(:, i) = double(conv(bin(:, i), mov_ave, 'same') > 0);
    end

elseif ~isempty(OBJ.options.binarize) & strcmp(lower(OBJ.options.binarize(1)), 't')

    thresh = nanmean(TRACE) + OBJ.options.binarize_sigma_t * nanstd(TRACE);
    idx = 1:size(TRACE, 1) - 1;
    bin = false(size(TRACE, 1) - 1, size(TRACE, 2));

    for i = 1:size(TRACE, 2)
        bin(:, i) = TRACE(idx, i) < thresh(i) & TRACE(idx + 1, i) >= thresh(i);
    end

    bin = [false(1, size(bin, 2)); bin];

    TRACE = bin;

end

if isvector(TRACE)
    TRACE = TRACE(:);

    if OBJ.options.clean_edge_effects > 0

        left_edge_mu = nanmean(TRACE(1:OBJ.options.clean_edge_effects));
        right_edge_mu = nanmean(TRACE(end - OBJ.options.clean_edge_effects:end));

        middle_mu = nanmean(TRACE(OBJ.options.clean_edge_effects:end - OBJ.options.clean_edge_effects));
        middle_mad = mad(TRACE(OBJ.options.clean_edge_effects:end - OBJ.options.clean_edge_effects), 0);

        if left_edge_mu > (middle_mu + middle_mad)
            TRACE(1:OBJ.options.clean_edge_effects) = nan;
        end

        if right_edge_mu > (middle_mu + middle_mad)
            TRACE(end - OBJ.options.clean_edge_effects:end) = nan;
        end

    end

end

if OBJ.options.rectify
    TRACE(TRACE < 0) = 0;
end

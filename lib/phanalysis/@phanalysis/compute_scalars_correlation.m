function compute_scalars_correlation(OBJ, SUPPRESS_OUTPUT)
% collects downsampled scalars and photometry data for running simple regression
%

if nargin < 2
    SUPPRESS_OUTPUT = false;
end

use_scalars = fieldnames(OBJ.projections(1).scalars);
use_syllables = length(unique(OBJ.behavior(1).states));

OBJ.stats.corr_scalars = struct();
fprintf('Collect data for scalar correlations...\n');

if ~SUPPRESS_OUTPUT
    upd = kinect_extract.proc_timer(length(OBJ.session));
end

OBJ.stats.corr_phot = struct('gcamp', [], 'rcamp', []);

if strcmp(char(OBJ.options.scalar_corr_binfun), 'nanmean')
    fast_ac = true;
else
    fast_ac = false;
end

for i = 1:length(OBJ.session)

    for j = 1:length(use_scalars)

        if strcmp(use_scalars{j}, 'angle')
            OBJ.stats.corr_scalars(i).(sprintf('%s', use_scalars{j})) = [];
            OBJ.stats.corr_scalars(i).(sprintf('%s_dt', use_scalars{j})) = [];
        else
            OBJ.stats.corr_scalars(i).(sprintf('%s', use_scalars{j})) = [];
        end

    end

    nsamples = numel(OBJ.projections(i).scalars.(use_scalars{1}));
    sample_idx = [1:nsamples];
    put_idx = ~isnan(OBJ.projections(i).proj_idx);
    put_vector = nan(nsamples, 1);

    if ~isempty(OBJ.behavior(i).labels) & strcmp(lower(OBJ.options.scalar_corr_bintype(1)), 's')
        put_vector(put_idx) = OBJ.behavior(i).labels;
    end

    switch lower(OBJ.options.scalar_corr_bintype(1))
        case 's'
            bin_edges = unique([sample_idx(1); find(abs(diff([put_vector(1); put_vector])) > 0); sample_idx(end)]);
        case 't'
            bin_edges = unique([sample_idx(1) sample_idx(1):OBJ.options.scalar_corr_binsize:sample_idx(end) sample_idx(end)]);
        otherwise
            error('Did not understand bin type, use either (s)yllables or (t)ime')
    end

    [~, ~, bin_idx] = histcounts(sample_idx, bin_edges);
    bin_idx = bin_idx(:);
    nbins = length(unique(bin_idx));

    OBJ.stats.corr_scalars(i).model_labels = accumarray(bin_idx, put_vector, [], @mode);
    OBJ.stats.corr_scalars(i).model_labels(OBJ.stats.corr_scalars(i).model_labels < 0) = nan;

    for j = 1:length(use_scalars)

        % smoove over the expected lags broheem

        tmp_scalar = OBJ.projections(i).scalars.(use_scalars{j});
        tmp_scalar_dt = diff([tmp_scalar(1); tmp_scalar]);

        len = length(tmp_scalar);

        acum_idx = ~isnan(tmp_scalar);

        tmp = accumarray(bin_idx(acum_idx), tmp_scalar(acum_idx), [nbins 1]);
        tmp2 = accumarray(bin_idx(acum_idx), ones(size(tmp_scalar(acum_idx))), [nbins 1]);
        tmp_scalar = tmp(:) ./ tmp2(:);

        tmp = accumarray(bin_idx(acum_idx), tmp_scalar_dt(acum_idx), [nbins 1]);
        tmp2 = accumarray(bin_idx(acum_idx), ones(size(tmp_scalar_dt(acum_idx))), [nbins 1]);
        tmp_scalar_dt = tmp(:) ./ tmp2(:);

        OBJ.stats.corr_scalars(i).(use_scalars{j}) = tmp_scalar;
        OBJ.stats.corr_scalars(i).(sprintf('%s_dt', use_scalars{j})) = tmp_scalar_dt;

    end

    switch lower(OBJ.data_type(1))

        case 'p'

            put_vector = nan(nsamples, 1);

            if OBJ.session(i).has_photometry & OBJ.session(i).use_gcamp
                put_vector(put_idx) = OBJ.normalize_trace(OBJ.photometry(i).traces(1).dff);

                if abs(OBJ.options.scalar_shift) > 0
                    smps = round(OBJ.options.scalar_shift .* OBJ.options.fs);
                    put_vector = circshift(put_vector, smps);
                end

                if fast_ac
                    tmp = accumarray(bin_idx(acum_idx), put_vector(acum_idx), [nbins 1]);
                    tmp2 = accumarray(bin_idx(acum_idx), ones(size(bin_idx(acum_idx))), [nbins 1]);
                    OBJ.stats.corr_phot(i).gcamp = tmp ./ tmp2;
                else
                    OBJ.stats.corr_phot(i).gcamp = accumarray(bin_idx, put_vector(:), [], OBJ.options.scalar_corr_binfun);
                end

            end

            put_vector = nan(nsamples, 1);

            if OBJ.session(i).has_photometry & OBJ.session(i).use_rcamp

                if length(OBJ.photometry(i).traces) > 4
                    put_vector(put_idx) = OBJ.normalize_trace(OBJ.photometry(i).traces(5).dff);
                else
                    put_vector(put_idx) = OBJ.normalize_trace(OBJ.photometry(i).traces(4).dff);
                end

                if abs(OBJ.options.scalar_shift) > 0
                    smps = round(OBJ.options.scalar_shift .* OBJ.options.fs);
                    put_vector = circshift(put_vector, smps);
                end

                if fast_ac
                    tmp = accumarray(bin_idx(acum_idx), put_vector(acum_idx), [nbins 1]);
                    tmp2 = accumarray(bin_idx(acum_idx), ones(size(bin_idx(acum_idx))), [nbins 1]);
                    OBJ.stats.corr_phot(i).rcamp = tmp ./ tmp2;
                else
                    OBJ.stats.corr_phot(i).rcamp = accumarray(bin_idx, put_vector(:), [], OBJ.options.scalar_corr_binfun);
                end

            end

        case 'i'

            if OBJ.session(i).has_imaging

                all_data = OBJ.normalize_trace([OBJ.imaging(i).traces(:).raw]);
                [nframes, nrois] = size(all_data);
                put_mat = nan(nsamples, nrois);
                bin_data = nan(nbins, nrois);

                put_mat(put_idx, :) = all_data;
                clear all_data;

                if abs(OBJ.options.scalar_shift) > 0
                    smps = round(OBJ.options.scalar_shift .* OBJ.options.fs);
                    put_mat = circshift(put_mat, [smps 1]);
                end

                acum_idx = ~isnan(put_mat(:, 1));

                for j = 1:nrois

                    if fast_ac
                        tmp = accumarray(bin_idx(acum_idx), put_mat(acum_idx, j), [nbins 1]);
                        tmp2 = accumarray(bin_idx(acum_idx), ones(size(bin_idx(acum_idx))), [nbins 1]);
                        bin_data(:, j) = tmp ./ tmp2;
                    else
                        bin_data(:, j) = accumarray(bin_idx, put_mat(:, j), [], OBJ.options.scalar_corr_binfun);
                    end

                end

                OBJ.stats.corr_imaging(i).data = bin_data;
            end

        otherwise
            error('Did not understand data type')
    end

    if ~SUPPRESS_OUTPUT
        upd(i);
    end

end

upd(inf);

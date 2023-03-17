function rereference(OBJ)
% reference all channels that haven't yet been rereferenced
%

for i = 1:length(OBJ)

    if length(OBJ(i).traces) < 1
        continue;
    end

    to_reref = find(cellfun(@(x) ~isempty(x), {OBJ(i).traces(:).reference_channel}));

    switch lower(OBJ(i).options.rereference_method(1))

        case 'v'

            for j = to_reref

                sig = OBJ(i).traces(j).baseline_rem;
                reference = OBJ(i).traces(OBJ(i).traces(j).reference_channel).baseline_rem;

                use_samples = ~(isnan(sig) | isnan(reference));

                num = sig(use_samples)' * reference(use_samples);
                den = reference(use_samples)' * reference(use_samples);

                OBJ(i).traces(j).reference = reference * (num / den);
                reref = sig - OBJ(i).traces(j).reference;

                OBJ(i).traces(j).dff_reref = reref ./ OBJ(i).traces(j).baseline;

            end

        case 'i'

            % ICA!, take component on red channel with stronger proportion in blue-->red
            % could also take component shared on lime-->green and blue-->red

            if exist('fastica') ~= 2
                error('Need fastica in your MATLAB path to use the ICA option!');
            end

            use_data = [OBJ(i).traces(OBJ(i).options.ica_channels).baseline_rem];

            nchannels = size(use_data, 2);

            for j = 1:nchannels
                nans = isnan(use_data(:, j));
                use_data(nans, j) = interp1(find(~nans), use_data(~nans, j), find(nans), 'linear', 0);
            end

            if OBJ(i).options.ica_smoothing > 0
                fs = 1 / OBJ(i).options.ica_smoothing;
                [smooth_b, smooth_a] = butter(3, fs / (OBJ(i).metadata.fs / 2), 'low');
                use_data = filtfilt(smooth_b, smooth_a, use_data);
            end

            if OBJ(i).options.ica_normalize
                use_data = zscore(use_data);
            else
                use_data = use_data * 1e3;
            end

            % get the separating matrix, store and use it to put together our reference

            [~, w] = fastica(use_data', 'verbose', 'off');

            % fix any sign flips, largest component is always positive

            if isempty(w)
                fprintf('Fast ica failed...returning\n');
                return;
            end

            [~, idx] = max(abs(w), [], 2);
            sn = sign(w(idx(:) + [0; 2]));
            w = w .* repmat(sn, [1 2]);
            OBJ(i).metadata.ica.w = w;

            % find the component with the largest ref-channel weight

            idx = OBJ(i).options.ica_channels == OBJ(i).options.ica_reference;

            weights = abs(w(:, idx)) ./ sum(abs(w(:, ~idx)), 2);
            [~, ref_idx] = max(weights);

            OBJ(i).metadata.ica.ref_idx = ref_idx;

            demixed = (w * use_data')';
            use_demixed = demixed(:, ref_idx);

            for j = to_reref

                if isfield(OBJ(i).traces(j), 'reref')
                    OBJ(i).traces = rmfield(OBJ(i).traces, 'reref');
                end

                tmp = OBJ(i).traces(j).baseline_rem;
                nans = isnan(tmp);

                if OBJ(i).options.ica_smoothing > 0
                    tmp(nans) = interp1(find(~nans), tmp(~nans), find(nans), 'linear', 0);
                    tmp = filtfilt(smooth_b, smooth_a, tmp);
                    tmp(nans) = nan;
                end

                % check sign flip

                use_demixed(nans) = nan;

                [scale_coef_pos, res_pos] = hifiber.vector_rejection(tmp, use_demixed);
                [scale_coef_neg, res_neg] = hifiber.vector_rejection(tmp, -use_demixed);

                if res_neg < res_pos
                    scale_coef = -scale_coef_neg;
                else
                    scale_coef = scale_coef_pos;
                end

                OBJ(i).traces(j).reference = use_demixed .* scale_coef;
                OBJ(i).traces(j).reference_scale = scale_coef;
                reref = (OBJ(i).traces(j).baseline_rem - OBJ(i).traces(j).reference);
                OBJ(i).traces(j).dff_reref = reref ./ OBJ(i).traces(j).baseline;

            end

        otherwise
            error('Did not understand rereferencing method ((v)ector and (l)east squares)');
    end

    %upd(i);

end

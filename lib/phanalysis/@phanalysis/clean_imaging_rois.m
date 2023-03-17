function clean_imaging_rois(OBJ)
%
%
%
%
%

roi_corr_nsamples = 5e3;

for i = 1:length(OBJ.imaging)

    fprintf('Cleaning object %i of %i\n', i, length(OBJ.imaging));

    if ~isempty(OBJ.options.roi_corr_threshold)

        all_data = [OBJ.imaging(i).traces(:).raw];
        [nsamples, nrois] = size(all_data);

        fprintf('Checking for duplicate rois...');

        tmp = corr(all_data(1:min(nsamples, roi_corr_nsamples), :), 'rows', 'pairwise');
        tmp = triu(tmp, 1);
        [r, c] = find(tmp > OBJ.options.roi_corr_threshold);
        to_rem = c(:);

        fprintf('success\n');
        fprintf('Found %i duplicates\n', length(to_rem));
        OBJ.imaging(i).remove_channels(to_rem);

    end

    if ~isempty(OBJ.options.roi_detrend_fcn) & ~isempty(OBJ.options.roi_detrend_win)

        fprintf('Removing baseline...');

        all_data = [OBJ.imaging(i).traces(:).raw];
        [nsamples, nrois] = size(all_data);

        nwin = round(OBJ.options.fs * OBJ.options.roi_detrend_win);

        if mod(nwin, 2) == 0
            nwin = nwin + 1;
        end

        baseline = [nan(floor(nwin / 2), nrois); all_data; nan(floor(nwin / 2), nrois)];

        % pad then remove the pad

        baseline = colfilt(baseline, [nwin 1], 'sliding', OBJ.options.roi_detrend_fcn);
        left_edge = floor(nwin / 2) + 1;

        baseline = baseline(left_edge:left_edge + (nsamples - 1), :);
        all_data = all_data - baseline;

        for j = 1:nrois
            OBJ.imaging(i).traces(j).raw = all_data(:, j);
        end

        fprintf('success\n');

    end

    %
    % mu=nanmean(all_data);
    % thresh=nanmedian(mu)+OBJ.options.imaging_outlier_sigma*mad(mu,1);
    % idx=find(mu>thresh);
    % OBJ.imaging(i).remove_channels(idx);

end

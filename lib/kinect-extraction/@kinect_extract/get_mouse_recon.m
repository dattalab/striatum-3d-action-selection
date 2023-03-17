function [FILLED_DATA, RECON] = get_mouse_recon(OBJ)
%
%
%
%

opts = OBJ.options.pca;
[FILLED_DATA, missing_value] = OBJ.load_oriented_frames('raw', false, 'use_transform', true);

nframes = size(FILLED_DATA, 3);
edge_size = size(FILLED_DATA, 1);
FILLED_DATA = reshape(FILLED_DATA, edge_size ^ 2, []);
missing_idx = FILLED_DATA == missing_value;

for j = 1:nframes
    tmp = FILLED_DATA(:, j);
    FILLED_DATA(missing_idx(:, j), j) = int16(mean(tmp(tmp > 0)));
end

FILLED_DATA = single(FILLED_DATA);
l2_error = 1e6;

for i = 1:opts.iters_recon

    % project
    % center data

    mu = mean(FILLED_DATA);
    cur_scores = OBJ.pca.coeffs(:, 1:opts.cut_recon)' * bsxfun(@minus, FILLED_DATA, mu);

    % RECONstruct with a low-d projection

    RECON = OBJ.pca.coeffs(:, 1:opts.cut_recon) * cur_scores;
    RECON = bsxfun(@plus, RECON, mu);
    RECON(RECON < 5) = 0;

    % fill in the missing data and repeat
    % do a little filtering after this step...

    for j = 1:nframes
        FILLED_DATA(missing_idx(:, j), j) = RECON(missing_idx(:, j), j);
        FILLED_DATA(RECON(:, j) == 0, j) = 0;
    end

    if strcmp(lower(opts.stopping(1)), 'e')

        old_l2_error = l2_error;
        use_missing_idx = find(~missing_idx(:, 1:opts.max_frames_norm));
        l2_error = norm(RECON(use_missing_idx) - FILLED_DATA(use_missing_idx));
        error_diff = (old_l2_error - l2_error) / old_l2_error;

        if error_diff > 0 & error_diff < opts.epsilon
            break;
        end

    end

end

RECON = reshape(RECON, edge_size, edge_size, []);
FILLED_DATA = process_frame(reshape(FILLED_DATA, edge_size, edge_size, []), 'med_filt_size', opts.med_filt_size);

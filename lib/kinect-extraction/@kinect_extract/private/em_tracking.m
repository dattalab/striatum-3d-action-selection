function [PXTHETA_RAW, PXTHETA_FILT, MU, SIGMA, INIT_MASK] = kinect_em_tracking(FRAMES, varargin)
%
% given mask and MOVIE, extract ROI time trace

% mult., froeb norm.
% TODO: counter

INIT_MASK = [];

opts = struct( ...
    'low', 10, ...
    'high', inf, ...
    'suppress_output', false, ...
    'open_reps', [], ...
    'open_size', [], ...
    'med_filt_size', [3 3], ...
    'ord_num_space', 1, ...
    'ord_size_space', [5 5], ...
    'theta_thresh', -inf, ...
    'em_debug_level', 0, ...
    'rho_mu', 0, ...
    'rho_sig', 0, ...
    'init', 'manual', ...
    'init_mu', [], ...
    'init_sig', [], ...
    'init_mask', [], ...
    'diag_covar', [], ...
    'theta_user_bound', 1e-10, ...
    'lambdas', 30, ...
    'deltall_thresh', - .2, ...
    'segment', false);

opts_names = fieldnames(opts);
nparams = length(varargin);

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

for i = 1:2:nparams

    if any(strcmp(varargin{i}, opts_names))
        opts.(varargin{i}) = varargin{i + 1};
    end

end

opts_cell = map_parameters(opts);

% TODO: option for memmap file (so we can feed the whole thing, no need to break it up)

[height, width, nframes] = size(FRAMES);
center = round([width / 2; height / 2]);

% correct any flips (mouse never immediately turns 180)...

PXTHETA_FILT = zeros(size(FRAMES), 'double');
PXTHETA_RAW = zeros(size(FRAMES), 'double');
MU = zeros(3, nframes, 'double');
SIGMA = zeros(3, 3, nframes, 'double');

% set up GUI to make initial guess

total_points = height * width;

[xgrid, ygrid] = meshgrid(1:width, 1:height);
xvec = xgrid(:);
yvec = ygrid(:);
tmp = FRAMES(:, :, 1);
zvec = double(tmp(:));
old_framell = -1e9;

new_features = double([xvec yvec zvec]);
raw_features = new_features;

string = ['Drag the ellipse around the approximate position of the mouse, ' ...
        ' double click inside the ellipse when finished'];

tmp = process_frame(tmp, opts_cell{:});

if isempty(opts.init_mu) | isempty(opts.init_sig)

    if strcmp(lower(opts.init(1)), 'a')

        % could iterate here to bootstrap...(random initialization points?)

        idx = tmp > 0 & FRAMES(:, :, 1) > opts.low & FRAMES(:, :, 1) < opts.high;

    else

        if isempty(opts.init_mask)
            opts.init_mask = ellipse_select(double(FRAMES(:, :, 1)), string);
        end

        INIT_MASK = opts.init_mask;
        idx = opts.init_mask > 0 & tmp > opts.low & tmp < opts.high;

    end

    features = double([xvec(idx) yvec(idx) zvec(idx)]);

    mu = mean(features);
    sig = cov(features);

else

    mu = opts.init_mu(:)';
    sig = opts.init_sig;

end

init_mu = mu;
init_sig = sig;

old_tmp = zeros(size(tmp));
old_features = new_features;
old_raw_features = raw_features;
frame_ll = 0;

bad_trial = false;
i = 1;

while i <= nframes

    tmp = FRAMES(:, :, i);
    tmp = process_frame(tmp, opts_cell{:});

    % first get likelihoods from the cleaned data

    new_features(:, 3) = double(tmp(:));

    pxtheta = mvnpdf(new_features, mu, sig);
    pxtheta = reshape(pxtheta, height, width);

    % if something weird happened (e.g. filtering too aggressive),
    % repeat with no filtering

    % if mean/sum<a certain number maybe we've been too aggressive...

    tmp_raw = FRAMES(:, :, i);
    raw_features(:, 3) = double(tmp_raw(:));
    pxtheta_raw = mvnpdf(raw_features, mu, sig);
    pxtheta_raw = reshape(pxtheta_raw, height, width);
    old_frame_ll = frame_ll;
    frame_ll = mean(pxtheta(:));

    if bad_trial
        % if something happened turn off the filters and try again...
        tmp = FRAMES(:, :, i);
        new_features(:, 3) = double(tmp(:));
        pxtheta = mvnpdf(new_features, mu, sig);
        pxtheta = reshape(pxtheta, height, width);
    end

    frame_ll = mean(pxtheta(:));

    if frame_ll < opts.theta_user_bound

        % if likelihood drops below the user_bound, have the user
        % fix the model

        fprintf('\nModel ambiguity detected, drag an ellipse over the mouse and double click inside to continue...\n');
        mask = ellipse_select(double(FRAMES(:, :, i)), string);
        fprintf('Continuing\n\n\n');
        caxis([0 80]);
        idx = mask > 0 & tmp > opts.low & tmp < opts.high;

        % update model

        idx = idx(:);
        [mu, sig, framell] = em_fullem(new_features(idx, :), mu, sig, 'lambda', opts.lambdas(1));

        % get new mean and covariance

    else

        % if the image fractionates, remove the least likely blobs

        if bad_trial
            idx = tmp > opts.low & tmp < opts.high;
        else
            idx = log(pxtheta) > opts.theta_thresh & tmp > opts.low & tmp < opts.high;
        end

        test = regionprops(pxtheta, 'PixelIdxList');

        if length(test) > 1 && opts.segment

            % get likelihood of each blob

            logl = nan(1, length(test));

            for j = 1:length(test)
                pxs = pxtheta(test(j).PixelIdxList);
                logl(j) = sum(log(pxs(pxs > eps)));
            end

            % delete all but the best blobs

            [~, locs] = sort(logl, 'ascend');

            for j = 1:length(locs) - 1
                idx(test(locs(j)).PixelIdxList) = false;
            end

        end

    end

    % also get likelihood of raw data

    idx = idx(:);

    % clamp rho at 1
    % also set rho to 0 if log-likelihood dips below a particular threshold

    if opts.em_debug_level > 0
        fprintf('Frame %i\n', i);
        figure(5);
        imagesc(log(pxtheta));
        caxis([-60 0])
        pause(.001);
    end

    % updates

    update_sucks = true;
    j = 1;

    % if update sucks, try increasing regularization and repeat

    while update_sucks & j <= length(opts.lambdas)

        try

            [mu_update, sig_update, framell] = em_fullem(new_features(idx, :), mu, sig, ...
                'lambda', opts.lambdas(j), 'diag_covar', opts.diag_covar);

            old_framell = framell;
            deltall = (framell - old_framell) ./ abs(old_framell);

            if deltall > opts.deltall_thresh
                update_sucks = false;
            end

        catch err
            rethrow(err)
        end

        j = j + 1;

    end

    % smoothing parameters for mu and sig
    % still update if it sucks?

    mu = (1 - opts.rho_mu) * mu_update + opts.rho_mu * mu;
    sig = (1 - opts.rho_sig) * sig_update + opts.rho_sig * sig;

    % store likelihood of the original data??

    PXTHETA_RAW(:, :, i) = pxtheta_raw;
    PXTHETA_FILT(:, :, i) = pxtheta;
    MU(:, i) = mu;
    SIGMA(:, :, i) = sig;

    % if the fitting fails, mu and sig drop to 0, use this as a sign to back off
    % on the filtering and retry

    if all(mu(:) == 0) | all(sig(:) == 0)

        if ~bad_trial
            % go back one frame, turn off filtering...
            bad_trial = true;
            % get the last good model estimate (remember this one is no good)
            if i > 1
                mu = MU(:, i - 1)';
                sig = SIGMA(:, :, i - 1);
            else
                mu = init_mu;
                sig = init_sig;
            end

        else
            error('Fitting failed on frame %i', i);
        end

    else
        bad_trial = false;
        i = i + 1;
    end

end

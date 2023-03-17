function [TRAIN_X, TRAIN_Y] = decode_photometry_collect_waveforms(PHAN, MODEL_STARTS, varargin)
%
%
%

opts = struct( ...
    'all_cut', 40, ...
    'window', [- .1 .3], ...
    'use_field', 'wins', ...
    'data_threshold', -inf, ...
    'use_duration', 'z', ...
    'warp_length', 10, ...
    'renormalize', false);

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

TRAIN_X = [];
TRAIN_Y = [];

rcamp_sessions = [MODEL_STARTS.rcamp(1, :).session_idx];
gcamp_sessions = [MODEL_STARTS.gcamp(1, :).session_idx];

intersession = intersect(unique(rcamp_sessions), unique(gcamp_sessions));

use_gcamp = ismember(gcamp_sessions, intersession);
use_rcamp = ismember(rcamp_sessions, intersession);

win_samples = round(PHAN.options.fs * opts.window);
win_samples_vec = win_samples(1):win_samples(2);
center = PHAN.options.max_lag;

for i = 1:opts.all_cut

    %opts.cluster_behavior=false;

    % grab all the waveforms for the syllable, stitch together gcamp and rcamp

    gcamp_waveforms = phanalysis.nanzscore(cat(2, MODEL_STARTS.gcamp(i, use_gcamp).(opts.use_field)));
    rcamp_waveforms = phanalysis.nanzscore(cat(2, MODEL_STARTS.rcamp(i, use_rcamp).(opts.use_field)));

    rcamp_meta = (cat(2, MODEL_STARTS.rcamp(i, use_rcamp).session_idx));

    win = center + win_samples(1):center + win_samples(2);
    durations = cat(1, MODEL_STARTS.gcamp(i, use_gcamp).durations);

    switch lower(opts.use_duration(1))

        case 'z'

            for j = 1:length(durations)
                gcamp_waveforms((center + durations(j)):end, j) = 0;
                rcamp_waveforms((center + durations(j)):end, j) = 0;
            end

            gcamp_waveforms = gcamp_waveforms(win, :);
            rcamp_waveforms = rcamp_waveforms(win, :);

        case 'w'

            warped_gcamp = nan(opts.warp_length, size(gcamp_waveforms, 2));
            warped_rcamp = nan(opts.warp_length, size(rcamp_waveforms, 2));

            for j = 1:length(durations)
                dur = max(durations(j), 2);
                x = linspace(1, opts.warp_length, dur + length(win_samples_vec));
                xx = 1:opts.warp_length;
                warped_gcamp(:, j) = interp1(x, ...
                    gcamp_waveforms(center + win_samples(1):center + dur + win_samples(2), j), xx);
                warped_rcamp(:, j) = interp1(x, ...
                    rcamp_waveforms(center + win_samples(1):center + dur + win_samples(2), j), xx);
            end

            gcamp_waveforms = warped_gcamp;
            rcamp_waveforms = warped_rcamp;

        otherwise

            gcamp_waveforms = gcamp_waveforms(win, :);
            rcamp_waveforms = rcamp_waveforms(win, :);

    end

    % remove waveforms where we don't get a response

    to_del = max(abs(gcamp_waveforms)) < opts.data_threshold | max(abs(rcamp_waveforms)) < opts.data_threshold;

    gcamp_waveforms(:, to_del) = [];
    rcamp_waveforms(:, to_del) = [];

    if opts.renormalize
        feature_mat = [zscore(gcamp_waveforms); zscore(rcamp_waveforms)];
    else
        feature_mat = [gcamp_waveforms; rcamp_waveforms];
    end

    TRAIN_X = [TRAIN_X single(feature_mat)];
    TRAIN_Y = [TRAIN_Y int16(ones(1, size(feature_mat, 2)) * i)];

end

TRAIN_X = TRAIN_X';
TRAIN_Y = TRAIN_Y';

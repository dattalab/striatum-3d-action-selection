function [PEAKS] = extract_syllable_onsets(PHAN, MODEL_STARTS, varargin)
%
%
%

opts = struct( ...
    'use_window', [.1 1], ...
    'offset', 0, ...
    'duration_window', [0 .05], ...
    'frac', 1, ...
    'use_field', 'wins', ...
    'use_id', '', ...
    'nrands', 0, ...
    'use_peaks', true, ...
    'randomize', false);

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

% for each behavior concatenate response and duration

PEAKS.gcamp = {};
PEAKS.rcamp = {};

nsyllables = PHAN.options.syllable_cutoff;
max_lag = PHAN.options.max_lag;
use_lag = max_lag + opts.offset;
[~, nsessions] = size(MODEL_STARTS.rcamp);

win_smps = round(PHAN.options.fs * opts.use_window);
duration_smps = round(PHAN.options.fs * opts.duration_window);

chk_fields = fieldnames(PEAKS);

for ii = 1:length(chk_fields)

    for i = 1:nsyllables

        session_ids = cat(1, MODEL_STARTS.(chk_fields{ii})(i, :).session_idx);
        ids = {PHAN.session(session_ids).mouse_id};

        if ~isempty(opts.use_id)
            session_match = strcmp(ids, opts.use_id);
        else
            session_match = true(size(session_ids));
        end

        session_match = find(session_match);

        win_cat = [];
        dur_cat = [];

        for j = 1:length(session_match)
            win_cat = [win_cat zscore(MODEL_STARTS.(chk_fields{ii})(i, session_match(j)).wins)];
            dur_cat = [dur_cat MODEL_STARTS.(chk_fields{ii})(i, session_match(j)).durations(:)'];
        end

        peaks = [];

        if isempty(opts.use_window) & ~opts.randomize

            for j = 1:length(dur_cat)
                win_smps = [duration_smps(1) max(floor(dur_cat(j) * opts.frac) - duration_smps(2), 0)];
                win_smps(2) = min(win_smps(2), (size(win_cat, 1) - use_lag));
                chunk = win_cat(use_lag - win_smps(1):use_lag + win_smps(2), j);

                if opts.use_peaks
                    [val, idx] = max(chunk);
                    peaks(j) = val .* sign(chunk(idx));
                else
                    peaks(j) = mean(chunk);
                end

            end

        elseif opts.randomize

            for j = 1:length(dur_cat)

                if isempty(opts.use_window)
                    win_smps = [duration_smps(1) max(floor(dur_cat(j) * opts.frac) - duration_smps(2), 0)];
                end

                use_lag = randi((max_lag * 2 + 1) - (sum(win_smps) + 1)) + win_smps(1);
                chunk = win_cat(use_lag - win_smps(1):use_lag + win_smps(2), j);

                if opts.use_peaks
                    [val, idx] = max(abs(chunk));
                    peaks(j) = val .* sign(chunk(idx));
                else
                    peaks(j) = mean(chunk);
                end

            end

        else
            chunk = win_cat(use_lag - win_smps(1):use_lag + win_smps(2), :);

            if opts.use_peaks
                [val, idx] = max(abs(chunk));

                for j = 1:size(chunk, 2)
                    peaks(j) = val(j) .* sign(chunk(idx(j), j));
                end

            else
                peaks = mean(chunk);
            end

        end

        PEAKS.(chk_fields{ii}){i} = peaks;
    end

end

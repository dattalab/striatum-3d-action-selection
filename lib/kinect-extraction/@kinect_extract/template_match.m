function [MATCH_IDX, MATCH_SCORE] = template_match(OBJ, SYLL_NUM, THRESH, NPCS)
%
%
%
%

if nargin < 4 | isempty(NPCS)
    NPCS = 10;
end

if nargin < 3 | isempty(THRESH)
    THRESH = 1;
end

if nargin < 2 | isempty(SYLL_NUM)
    SYLL_NUM = 1;
end

MATCH_IDX = [];
MATCH_SCORE = [];
% first create a template

slop = 3;
durs = OBJ.behavior_model.state_durations{SYLL_NUM};
dur_mode = mode(durs);

use_mode = dur_mode;

if mod(use_mode, 2) == 0
    use_mode = use_mode + 1;
end

% interpolate nans

use_pcs = OBJ.get_original_timebase(OBJ.projections.pca(:, 1:NPCS));
idx = 1:size(use_pcs, 1);

for j = 1:NPCS
    nans = isnan(use_pcs(:, j));
    use_pcs(nans, j) = interp1(idx(~nans), use_pcs(~nans, j), idx(nans), 'spline');
end

if isnan(use_mode)
    return;
end

wins = phanalysis.window_data((use_pcs), ...
    OBJ.behavior_model.state_starts{SYLL_NUM}(dur_mode), use_mode + 3);

% average everything after the onset

template = (nanmean(wins(use_mode:end, :, :), 3));
win_samples = fix(size(template, 1) / 2);

% now scan over the pcs, return indices

nframes = OBJ.metadata.nframes;

% zero pad the pcs
% local or global zscore???

zero_pad = zeros(size(template, 1), NPCS);
target_signal = [zero_pad; (use_pcs); zero_pad];

MATCH_SCORE = zeros(nframes, 1);
upd = kinect_extract.proc_timer(nframes, 'frequency', 200);

for i = 1:nframes
    pos = i + size(zero_pad, 1);
    MATCH_SCORE(i) = norm((target_signal(pos:pos + win_samples * 2, :)) - template, 2);
    upd(i);
end

MATCH_SCORE = -zscore(MATCH_SCORE);
MATCH_SCORE(MATCH_SCORE < 0) = 0;
MATCH_SCORE = MATCH_SCORE .^ 2;
MATCH_SCORE = zscore(MATCH_SCORE);

% find peaks dun dun dun
warning('off', 'signal:findpeaks:largeMinPeakHeight');
[~, MATCH_IDX] = findpeaks(MATCH_SCORE, 'minpeakheight', THRESH, 'minpeakdistance', use_mode);
warning('on', 'signal:findpeaks:largeMinPeakHeight');

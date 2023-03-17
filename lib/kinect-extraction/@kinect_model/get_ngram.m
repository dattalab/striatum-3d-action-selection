function [SYMBOLS, COUNTS] = get_ngram(OBJ, N, FRAME_IDX)
%
%
%
%

if nargin < 3
    FRAME_IDX = [1 inf];
end

if nargin < 2
    N = 2;
end

% stitch together the sequence and then count!
seq = [];

for i = 1:length(OBJ)

    nframes = length(OBJ(i).labels);
    use_frames = FRAME_IDX;

    if use_frames(2) > nframes
        use_frames(2) = nframes;
    end

    tmp = OBJ(i).labels(use_frames(1):use_frames(2));
    tmp = double(tmp(find(diff(tmp))));

    seq = [seq; nan; tmp];

end

seq_len = length(seq);

countmat = zeros(seq_len - (N - 1), N);

for i = 1:N
    countmat(:, i) = seq(1 + (i - 1):seq_len - (N - i));
end

countmat(any(isnan(countmat) | countmat < 0, 2), :) = [];
[SYMBOLS, ~, idx] = unique(countmat, 'rows');
COUNTS = accumarray(idx, 1);

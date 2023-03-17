function [MAT, COL_IDX] = vec_to_mat(DATA, NWIN, NOVERLAP)
%
%

if nargin < 3 | isempty(NOVERLAP)
    NOVERLAP = 0;
end

if nargin < 2 | isempty(NWIN)
    NWIN = floor(DATA / 100);
end

% mostly cribbed from MATLAB's old specgram
% efficient way to reformat vectors for sliding window calculations...
len = length(DATA);

ncol = fix((len - NOVERLAP) / (NWIN - NOVERLAP));
colindex = 1 + (0:(ncol - 1)) * (NWIN - NOVERLAP);
rowindex = (1:NWIN)';

MAT = zeros(NWIN, ncol);
MAT(:) = DATA(rowindex(:, ones(1, ncol)) + colindex(ones(NWIN, 1), :) - 1);
COL_IDX = colindex - 1;

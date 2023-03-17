function [MAT, T] = vec2mat(DATA, NWIN, NOVERLAP)
%
% mostly cribbed from MATLAB's old specgram
% efficient way to reformat vectors for sliding window calculations...

len = length(DATA);

ncol = fix((len - NOVERLAP) / (NWIN - NOVERLAP));
colindex = 1 + (0:(ncol - 1)) * (NWIN - NOVERLAP);
rowindex = (1:NWIN)';

MAT = zeros(NWIN, ncol);
MAT(:) = DATA(rowindex(:, ones(1, ncol)) + colindex(ones(NWIN, 1), :) - 1);
T = colindex - 1 + ceil(NWIN / 2); % get index from the *center* of the window

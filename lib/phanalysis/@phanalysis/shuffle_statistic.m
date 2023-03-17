function [SHUFFLE_STAT, SAVE_MAT, SAVE_SHUFFLES] = shuffle_statistic(FUN, MATRIX, NSHUFFLES, SUPPRESS_OUTPUT)
%
%
%

if nargin < 4
    SUPPRESS_OUTPUT = false;
end

if nargin < 3 | isempty(NSHUFFLES)
    NSHUFFLES = 100;
end

[r, c] = size(MATRIX);

% get the size of whatever function returns

if isvector(MATRIX)
    junk = FUN(MATRIX(:));
else
    junk = FUN(MATRIX);
end

assert(isvector(junk), 'Dimensionality of Fun output must be 1');

SHUFFLE_STAT = nan(length(junk), NSHUFFLES);
%
if ~SUPPRESS_OUTPUT
    upd = kinect_extract.proc_timer(NSHUFFLES);
end

fftmat = fft(MATRIX, [], 2);

% parfor is wasted with the fft here, already multi-threaded

for i = 1:NSHUFFLES

    shuffles = randi([1 c], [r 1]);
    tmp_shuffle = real(ifft(fftmat .* exp(1j .* 2 * pi / c .* shuffles .* [0:c - 1]), [], 2));
    SHUFFLE_STAT(:, i) = FUN(tmp_shuffle);

    if ~SUPPRESS_OUTPUT
        upd(i);
    end

end

SAVE_MAT = tmp_shuffle;
SAVE_SHUFFLES = shuffles;

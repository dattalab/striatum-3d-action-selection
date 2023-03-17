function RND_DATA = phase_randomize(DATA, NRANDS)
%
%
%
%
%

if nargin < 2 | isempty(NRANDS)
    NRANDS = 1;
end

assert(isvector(DATA), 'DATA must be a vector');
DATA = DATA(:);

tmp_fft = fft(DATA);
mag = abs(tmp_fft);
ang = angle(tmp_fft);
mag = mag(:);
ang = ang(:);

% generate nrands permutations

[~, permidx] = sort(rand(numel(ang), NRANDS));

% synthesize the phase scrambled versions

RND_DATA = single(real(ifft(repmat(mag, [1 NRANDS]) .* exp(1j .* ang(permidx)))));

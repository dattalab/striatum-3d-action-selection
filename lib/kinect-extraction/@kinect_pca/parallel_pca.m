function [COEFFS, LATENT, EXPLAINED, COV] = parallel_pca(DATA, varargin)
%
%
%
%
%
%

opts = struct( ...
    'chunk_size', 1e4, ...
    'use_fft', false);

mem_var = 'cat_frames';
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

is_memmap = false;

if isa(DATA, 'matlab.io.MatFile')
    [nvars, nobservations] = size(DATA, mem_var);
    FRAMES.Properties.Writable = true;
    is_memmap = true;
else
    [nvars, nobservations] = size(DATA);
end

steps = unique([0:opts.chunk_size:nobservations nobservations]);
idx = 0;

cur_sum_sq = zeros(nvars, nvars);
cur_sum = zeros(nvars, 1);

% lessons I have learned:
% 1) parfor is stupid here, can't get around communication overhead
% 2) MATLAB's "implicit" multithreading is WAY FASTER
% 3) what was I thinking?

for i = 1:length(steps) - 1

    if ~is_memmap
        tmp = single(DATA(:, steps(i) + 1:steps(i + 1)));
    else
        tmp = single(DATA.(mem_var)(:, steps(i) + 1:steps(i + 1)));
    end

    if opts.use_fft
        tmp = abs(fft2(reshape(tmp, sqrt(nvars), sqrt(nvars), [])));
        tmp = reshape(tmp, nvars, []);
    end

    nsamples = size(tmp, 2);

    % yes it's the "naive algorithm" according to wikipedia, not seeing a big difference with the fancier version

    cur_sum = cur_sum + sum(tmp, 2);
    cur_sum_sq = cur_sum_sq + tmp * tmp';

end

% note that MATLAB normalizes mean with nsamples and covariance with nsamples-1

cur_estimate = (cur_sum_sq - (cur_sum * cur_sum') / nobservations) ./ (nobservations - 1);

if ~is_memmap
    clear DATA;
end

% pcacov uses svd, not sure we need the extra precision

[COEFFS, LATENT] = eig(cur_estimate);
LATENT = diag(LATENT);

[~, idx] = sort(LATENT, 'descend');
LATENT = LATENT(idx);
COEFFS = COEFFS(:, idx);
EXPLAINED = 100 * LATENT / sum(LATENT);

% neat trick to enforce a sign convention ripped from pcacov

[r, c] = size(COEFFS);
[~, max_ind] = max(abs(COEFFS), [], 1);
col_sign = sign(COEFFS(max_ind + (0:r:(c - 1) * r)));

COEFFS = bsxfun(@times, COEFFS, col_sign);

%[COEFFS,LATENT,EXPLAINED]=pcacov(cur_estimate);
%COV=cur_estimate./idx;
%fprintf('PCA complete...\n');
COV = cur_estimate;

function [U S V OMEGA] = kinect_randsvd(M, K, OMEGA)
% Halko et al. algorithm (i.e. the simplest one)
%
%
%
[m, n] = size(M);
p = min(2 * K, n);

if nargin < 3 | isempty(OMEGA)
    OMEGA = randn(n, p);
end

% ensure the data is demeaned

M = single(M);
randproj = M * OMEGA;

% 1) draw mvnpdf from N(0,1)
% 2) project onto random matrix
% 3) truncated svd on projection

w1 = orth(randproj);
b = w1' * M;
[w2, S, V] = svd(b, 'econ');
U = w1 * w2;
K = min(K, size(U, 2));
U = U(:, 1:K);
S = S(1:K, 1:K);
V = V(:, 1:K);

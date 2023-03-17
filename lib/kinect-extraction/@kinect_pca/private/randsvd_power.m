function [U S V OMEGA] = kinect_randsvd_power(M, K, Q, OMEGA)
% liberally cribbed from http://arxiv.org/pdf/1505.07570.pdf
%
% Block Krylov method

s = 2 * K;
[m, n] = size(M);

if nargin < 4 | isempty(OMEGA)
    OMEGA = randn(n, s);
end

M = single(M);
C = M * OMEGA;

krylov = zeros(m, s * Q);
krylov(:, 1:s) = C;

for i = 2:Q
    C = M' * C;
    C = M * C;
    [C, ~] = qr(C, 0);
    kyrlov(:, (i - 1) * s + 1:i * s) = C;
end

[Q, ~] = qr(krylov, 0);
[ubar, S, V] = svd(Q' * M, 'econ');

ubar = ubar(:, 1:K);
S = S(1:K, 1:K);
V = V(:, 1:K);
U = Q * ubar;

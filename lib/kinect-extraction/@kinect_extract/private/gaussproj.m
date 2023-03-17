function PROJ = kinect_gaussproj(M, K)
% Gaussian random projection
%

[m, n] = size(M);
rotation = randn(n, K) / sqrt(K);
PROJ = M * rotation;

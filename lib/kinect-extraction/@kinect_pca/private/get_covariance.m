function [COV, MU, N] = kinect_get_covariance(DATA)
%
%
%
%
%
%

N = size(DATA, 1);
DATA = bsxfun(@minus, DATA, mean(DATA));
COV = (DATA' * DATA) / (N - 1);
MU = mean(DATA);

function MERGE = kinect_merge_covariance(COV1, COV2, MU1, MU2, N1, N2)
% Merge cov estimates using the update formula from Phillippe Pebay (also on Wikipedia)
% http://prod.sandia.gov/techlib/access-control.cgi/2008/086212.pdf
%
%
%

% yup that's it!

delt = MU1(:) - MU2(:);
MERGE = COV1 + COV2 + (delt(:) * delt(:)') * ((N1 * N2) / (N1 + N2));

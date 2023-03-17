function M = im_moment_cent(IM, XBAR, YBAR, P, Q, ISLIST)
%
%
%
%

if ~ISLIST
    [height, width] = size(IM);
    [XX, YY] = meshgrid(1:width, 1:height);
    ZZ = IM(:);
else
    XX = IM(:, 1);
    YY = IM(:, 2);
    ZZ = ones(size(XX));
end

XX = XX(:) - XBAR;
YY = YY(:) - YBAR;
M = sum(XX .^ P .* YY .^ Q .* ZZ) / sum(ZZ);

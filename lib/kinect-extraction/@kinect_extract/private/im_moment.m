function M = im_moment(IM, P, Q, ISLIST)
%
%
%
%

[height, width] = size(IM);

if ~ISLIST
    [XX, YY] = meshgrid(1:width, 1:height);
    ZZ = IM(:);
    XX = XX(:);
    YY = YY(:);
else
    XX = IM(:, 1);
    YY = IM(:, 2);
    ZZ = ones(size(XX));
end

M = sum(XX .^ P .* YY .^ Q .* ZZ) / sum(ZZ);

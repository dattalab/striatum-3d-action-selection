function unify_caxis(AX, PRECISION)
%
%
%
%

if nargin < 2 | isempty(PRECISION)
    PRECISION = 1e-2;
end

if nargin < 1 | isempty(AX)
    AX = findall(gcf, 'type', 'axes');
end

caxes = nan(length(AX), 2);

for i = 1:length(AX)
    AX(i)
    caxes(i, :) = AX(i).CLim;
end

new_caxes = round(mean(caxes) * 1 / PRECISION) * PRECISION;

for i = 1:length(AX)
    AX(i).CLim = new_caxes;
end

function DATA = get_projection_timebase(OBJ, DATA)
%
%
%
%
%

if nargin < 2
    DATA = [];
end

if isempty(DATA)
    DATA = @(x) get_projection_timebase(OBJ, x);
    return
end

nanidx = ~isnan(OBJ.projections.proj_idx);
len = sum(nanidx == true);

tmp = DATA;

if isvector(DATA) & numel(DATA) == len
    DATA = nan(numel(nanidx), 1);
    DATA(nanidx) = tmp;
elseif ndims(DATA) == 2 & size(DATA, 1) == len
    DATA = nan(numel(nanidx), size(DATA, 2));
    DATA(nanidx, :) = tmp;
else
    error('Data size is incorrect (must be %i samples)', len);
end

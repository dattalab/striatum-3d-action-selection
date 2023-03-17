function DATA = get_original_timebase(IDX, DATA)
%
%
%

if nargin < 2
    DATA = [];
end

if isempty(DATA)
    DATA = @(x) phanalysis.get_original_timebase(IDX, x);
    return
end

nanidx = ~isnan(IDX);

if isvector(DATA) & numel(DATA) == numel(nanidx)
    DATA = DATA(nanidx);
elseif ndims(DATA) == 2 & size(DATA, 1) == numel(nanidx)
    DATA = DATA(nanidx, :);
else
    error('Data size is incorrect (must be %i samples)', numel(nanidx));
end

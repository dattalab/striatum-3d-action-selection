function MASK = get_largest_blob(IMAGE)
%
%
%
%
%

cc = bwconncomp(IMAGE);
lens = cellfun(@length, cc.PixelIdxList);
[~, idx] = max(lens);

if isempty(idx)
    MASK = IMAGE;
    return;
end

MASK = false(size(IMAGE));
MASK(cc.PixelIdxList{idx}) = true;

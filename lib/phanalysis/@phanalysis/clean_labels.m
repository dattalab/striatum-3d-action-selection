function LABELS = CLEAN_LABELS(LABELS)
%
%
%
%

[uniq_labels, ~, tmp] = unique(LABELS);
tmp(tmp = find(isnan(uniq_labels))) = nan;

LABELS = tmp;

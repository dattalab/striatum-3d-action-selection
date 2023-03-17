function P = holm_bonf(P)
% Holm-bonferonni step-down procedure
%
%

assert(isvector(P), 'P must be a vector');

[~, idx] = sort(P, 'ascend');
m = [length(P):-1:1];
P = P .* m(idx);

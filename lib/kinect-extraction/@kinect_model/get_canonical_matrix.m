function BIG_A = get_canonical_matrix(A)
%
%
%

% we're assuming we're affine here...

A = squeeze(A);
sz = size(A);
npcs = sz(1);
nlags = (sz(2) - 1) / npcs;
A(:, end) = [];
BIG_A = zeros(npcs * nlags, npcs * nlags);
BIG_A(1:end - npcs, npcs + 1:end) = eye(npcs * (nlags - 1));
BIG_A(end - (npcs - 1):end, :) = A;

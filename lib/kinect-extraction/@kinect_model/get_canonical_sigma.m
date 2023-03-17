function BIG_SIG = get_canonical_sigma(SIG, NLAGS)
%
%
%

SIG = squeeze(SIG);
npcs = size(SIG, 1);

BIG_SIG = zeros(npcs * NLAGS, npcs * NLAGS);
BIG_SIG(end - (npcs - 1):end, end - (npcs - 1):end) = SIG;

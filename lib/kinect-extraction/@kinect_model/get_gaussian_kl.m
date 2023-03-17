function KL = get_gaussian_kl(M1, S1, M2, S2)
%
%
%
%

npcs = size(S2, 1);
KL = .5 * trace(linsolve(S2, S1));
dm = M2 - M1;
KL = KL + .5 * dot(dm, linsolve(S2, dm));
KL = KL - .5 * npcs;
KL = KL + .5 * log(det(S2));
KL = KL - .5 * log(det(S1));

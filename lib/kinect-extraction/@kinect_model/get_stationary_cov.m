function COV = get_stationary_cov(A, SIG)
%
%
%
%
%

A = squeeze(A);
sz = size(A);
npcs = sz(1);
nlags = (sz(2) - 1) / npcs;
big_a = kinect_model.get_canonical_matrix(A);
big_sig = kinect_model.get_canonical_sigma(SIG, nlags);
COV = dlyap(big_a, big_sig);

function MU=get_stationary_mean(A)
% Assuming affine terms is appended here...
%
%
%

A=squeeze(A);

sz=size(A);
npcs=sz(1);
nlags=(sz(2)-1)/npcs;

big_b=zeros(npcs*nlags,1);
big_b(end-(npcs-1):end,1)=A(:,end);
big_a=kinect_model.get_canonical_matrix(A);
MU=linsolve(eye(npcs*nlags)-big_a,big_b);

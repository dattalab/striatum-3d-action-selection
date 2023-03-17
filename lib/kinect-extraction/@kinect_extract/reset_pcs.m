function reset_pcs(OBJ)
%
%
%
%

for i = 1:length(OBJ)
    OBJ(i).pca = kinect_pca;
end

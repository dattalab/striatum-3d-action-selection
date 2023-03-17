function reset_behavior_model(OBJ)
%
%
%
%

for i = 1:length(OBJ)
    OBJ(i).behavior_model = kinect_model;
end

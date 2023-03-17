function BEH_OBJ = get_behavior_object(OBJ)
%
%
%

BEH_OBJ = kinect_model.empty(0, length(OBJ));

for i = 1:length(OBJ)
    BEH_OBJ(i) = OBJ(i).behavior_model;
end

function copy_options(OBJ)
% Copies options from the first object to the rest of the array
%

for i = 2:length(OBJ)
    OBJ(i).options = OBJ(1).options;
end

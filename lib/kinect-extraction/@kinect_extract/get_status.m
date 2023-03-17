function STATUS = get_status(OBJ)
%
%
%
%

for i = 1:length(OBJ)
    STATUS(i) = OBJ(i).status;
end

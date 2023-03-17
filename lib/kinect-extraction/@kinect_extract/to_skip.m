function SKIP = to_skip(OBJ)
%
%
%

SKIP = false(1, length(OBJ));

for i = 1:length(OBJ)
    SKIP(i) = OBJ(i).files.skip{2};
end

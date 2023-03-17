function subtract_baseline(OBJ)
%
%

for i = 1:length(OBJ)

    for j = 1:length(OBJ(i).traces)
        OBJ(i).traces(j).baseline_rem = OBJ(i).traces(j).raw - OBJ(i).traces(j).baseline;
    end

end

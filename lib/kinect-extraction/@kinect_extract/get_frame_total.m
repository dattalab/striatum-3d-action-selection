function TOTAL = get_frame_total(OBJ)
%
%
%
%

TOTAL = 0;

for i = 1:length(OBJ)
    TOTAL = TOTAL + OBJ(i).metadata.nframes;
end

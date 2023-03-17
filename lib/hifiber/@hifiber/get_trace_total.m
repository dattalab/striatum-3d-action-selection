function TRACE_TOTAL = get_trace_total(OBJ)
%
%
%
TRACE_TOTAL = 0;

for i = 1:length(OBJ)
    TRACE_TOTAL = TRACE_TOTAL + length(OBJ(i).traces);
end

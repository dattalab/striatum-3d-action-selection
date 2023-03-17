function set_cell_types(OBJ, SESSION_ID, TRACE_ID, CELL_TYPE, PROBA)
%
%
%
%
%

if nargin < 5 | isempty(PROBA)
    PROBA = nan;
end

assert(length(SESSION_ID) == length(TRACE_ID));

for i = 1:length(SESSION_ID)
    OBJ.imaging(SESSION_ID(i)).traces(TRACE_ID(i)).cell_type = CELL_TYPE;
    OBJ.imaging(SESSION_ID(i)).traces(TRACE_ID(i)).cell_type_proba = PROBA;
end

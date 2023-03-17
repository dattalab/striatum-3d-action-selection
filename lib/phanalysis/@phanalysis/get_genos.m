function GENOS = get_genos(OBJ)
%
%
%
%

GENOS = cell(size(OBJ.session));

for i = 1:length(OBJ.session)
    GENOS{i} = lower(OBJ.session(i).group);
end

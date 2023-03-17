function EXCLUDED = is_excluded(OBJ)
%
%
%
%

EXCLUDED = true(size(OBJ));

for i = 1:length(OBJ)

    if isfield(OBJ(i).metadata, 'mouse') & isstruct(OBJ(i).metadata.mouse)
        EXCLUDED(i) = strcmp(lower(OBJ(i).metadata.mouse.Exclude), 'yes');
    end

end

function load_mouse_metadata(OBJ, FILE)
%
%
%
%

% loads mouse metadata, applies to the appropriate object

tmp = loadjson(FILE);


tmp = [tmp{:}];

mouse_ids = {OBJ(:).mouse_id};

for i = 1:length(tmp)
    idx = find(contains(mouse_ids, tmp(i).Name));

    for j = 1:length(idx)
        OBJ(idx(j)).metadata.mouse = tmp(i);
    end

end

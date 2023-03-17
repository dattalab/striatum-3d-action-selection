function load_exclude_file(OBJ, JSONFILE)
%
%
%

tmp = loadjson(JSONFILE);

for i = 1:length(tmp)

    if isfield(tmp{i}, 'Reason')
        tmp{i} = rmfield(tmp{i}, 'Reason');
    end

end

OBJ.metadata.exclude = [tmp{:}];

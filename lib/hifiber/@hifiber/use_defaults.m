function use_defaults(OBJ);
%
%
%
%

[pathname, ~, ~] = fileparts(mfilename('fullpath'));
def_options = fullfile(pathname, 'defaults.config');
struct = read_options(def_options);
categories = fieldnames(struct);

for i = 1:length(OBJ)

    for j = 1:length(categories)
        OBJ(i).options.(categories{j}) = struct.(categories{j});
    end

end

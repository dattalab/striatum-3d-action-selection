function use_defaults(OBJ);
%
%
%
%

[pathname, ~, ~] = fileparts(mfilename('fullpath'));
def_options = fullfile(pathname, 'defaults.config');
struct = read_options(def_options);
categories = fieldnames(struct);

for i = 1:length(categories)

    if isprop(OBJ, categories{i})
        OBJ.(categories{i}) = struct.(categories{i});
    end

end

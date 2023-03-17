function set_options_from_file(OBJ, FILE);
% Makes sure the user sets options correctly
%
%
%

struct = read_options(def_options);
categories = fieldnames(struct);

for i = 1:length(categories)
    options = fieldnames(struct.(categories{i}));

    for j = 1:length(options)
        set(OBJ, (categories{i}), options{j}, struct.(categories{i}).(options{j}))
    end

end

function set_options_from_file(OBJ, FILE);
% Makes sure the user sets options correctly
%
%
%

struct = read_options(FILE);
categories = fieldnames(struct);

for i = 1:length(OBJ)

    for j = 1:length(categories)
        options = fieldnames(struct.(categories{j}));

        for k = 1:length(options)
            OBJ(i).options.(categories{j}).(options{k}) = struct.(categories{j}).(options{k});
        end

    end

end

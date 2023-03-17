function OPTIONS = read_options(FILENAME)
% script for reading config files/sorting for processing/chopping
%
% takes logfile as input
%
%
%

OPTIONS = struct();
fid = fopen(FILENAME, 'r');
readdata = textscan(fid, '%s%[^\n]', 'commentstyle', '#', 'delimiter', '=');
fclose(fid);

for i = 1:length(readdata{1})

    insert_data = readdata{2}{i};
    insert_data = regexprep(insert_data, '''', '');
    %insert_data=regexprep(insert_data,'''$','');

    OPTIONS.(readdata{1}{i}) = insert_data;

    if ~isempty(insert_data) & (insert_data(1) == '{' & insert_data(end) == '}')
        tmp = regexp(insert_data(2:end - 1), ',', 'split');
        OPTIONS.(readdata{1}{i}) = cell(1, length(tmp));

        for j = 1:length(tmp)
            OPTIONS.(readdata{1}{i}){j} = tmp{j};
        end

        continue;
    end

    % convert nums and vectors

    tmp = regexpi(OPTIONS.(readdata{1}{i}), '^[0-9;.:e-]+$||(true)|(false)', 'match');
    tmp2 = regexpi(OPTIONS.(readdata{1}{i}), '^\[([0-9;.:e-]+|([0-9;.:e-]+ )+[0-9;.:e-]+)\]|([i|I]nf)|(\[\])$', 'match');
    tmp3 = regexpi(OPTIONS.(readdata{1}{i}), '^\@', 'match');

    if ~isempty(tmp3)
        OPTIONS.(readdata{1}{i}) = eval(OPTIONS.(readdata{1}{i}));
    elseif (~isempty(tmp) | ~isempty(tmp2))
        OPTIONS.(readdata{1}{i}) = str2num(OPTIONS.(readdata{1}{i}));
    end

end

OPTIONS = orderfields(OPTIONS);

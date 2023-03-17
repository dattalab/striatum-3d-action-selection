function OPTIONS = kinect_read_options(FILENAME)
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

read_start = false;

% get all headers

section_headers = {};

for i = 1:length(readdata{1})

    if strcmp(readdata{1}{i}(1), '%')
        section_headers{end + 1} = lower(readdata{1}{i}(2:end));
    end

end

for ii = 1:length(section_headers)

    for i = 1:length(readdata{1})

        if strcmp(readdata{1}{i}(1), '%')

            % section headers begin with % sign

            if any(strcmpi(readdata{1}{i}(2:end), section_headers{ii}))
                read_start = true;
            else
                read_start = false;
            end

            continue;

        end

        if read_start

            insert_data = readdata{2}{i};
            insert_data = regexprep(insert_data, '''', '');
            %insert_data=regexprep(insert_data,'''$','');

            OPTIONS.(section_headers{ii}).(readdata{1}{i}) = insert_data;

            if ~isempty(insert_data) & (insert_data(1) == '{' & insert_data(end) == '}')
                tmp = regexp(insert_data(2:end - 1), ',', 'split');
                OPTIONS.(section_headers{ii}).(readdata{1}{i}) = cell(1, length(tmp));

                for j = 1:length(tmp)
                    OPTIONS.(section_headers{ii}).(readdata{1}{i}){j} = tmp{j};
                end

                continue;
            end

            % convert nums and vectors

            tmp = regexpi(OPTIONS.(section_headers{ii}).(readdata{1}{i}), '^[0-9;.:e-]+$|([e|E]ps)|(true)|(false)', 'match');
            tmp2 = regexpi(OPTIONS.(section_headers{ii}).(readdata{1}{i}), '^\[([0-9;.:e-]+|([0-9;.:e-]+ )+[0-9;.:e-]+)\]|([i|I]nf)|(\[\])$', 'match');

            if (~isempty(tmp) | ~isempty(tmp2))
                OPTIONS.(section_headers{ii}).(readdata{1}{i}) = str2num(OPTIONS.(section_headers{ii}).(readdata{1}{i}));
            end

        end

    end

end

OPTIONS = orderfields(OPTIONS);

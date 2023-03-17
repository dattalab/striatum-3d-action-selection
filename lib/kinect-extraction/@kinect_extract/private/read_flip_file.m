function FLIPS = read_flip_file(FILE)
%
%
%

fid = fopen(FILE, 'rt');
data = fgetl(fid);
fclose(fid);

if data ~= -1
    tmp = regexp(data, ',', 'split');
    FLIPS = nan(1, length(tmp));

    for i = 1:length(FLIPS)
        FLIPS(i) = str2num(tmp{i});
    end

else
    FLIPS = [];
end

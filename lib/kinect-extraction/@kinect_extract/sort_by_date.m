function IDX = sort_by_date(OBJ)
%
%
%

% get all the datenums

datenums = nan(size(OBJ));

for i = 1:length(OBJ)
    datenums(i) = OBJ(i).metadata.datenum;
end

[~, IDX] = sort(datenums, 'ascend');

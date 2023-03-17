function IDX = filter_by_date(OBJ, DATES)
%
%
%

datenums = nan(size(OBJ));

for i = 1:length(OBJ)
    datenums(i) = OBJ(i).metadata.datenum;
end

IDX = false(size(datenums));

if iscell(DATES)
    check_dates = nan(size(DATES));

    for i = 1:length(DATES)
        check_dates(i) = datenum(DATES{i}, 'mm/dd/yyyy');
    end

elseif isnumeric(DATES)
    check_dates = DATES;
elseif ischar(DATES)
    check_dates = datenum(DATES, 'mm/dd/yyyy');
else
    error('I give up')
end

for i = 1:length(datenums)
    tmp = datenums(i) - check_dates;
    IDX(i) = any(tmp >= 0 & tmp < 1);
end

function IDX = load_group_file(OBJ, GROUP_FILE, USE_SESSION, DEFAULT_NAME)
%
%
%
%

if nargin < 4 | isempty(DEFAULT_NAME)
    DEFAULT_NAME = 'ctrl';
end

if nargin < 3 | isempty(USE_SESSION)
    USE_SESSION = false;
end

metadata = loadjson(GROUP_FILE);
IDX = false(size(OBJ));

for i = 1:length(OBJ)

    chks = false(size(metadata));

    for j = 1:length(metadata)
        tmp_struct = metadata{j};
        flags = [true true];

        if isfield(tmp_struct, 'Name')
            flags(1) = OBJ(i).filter_by_mouse(tmp_struct.Name);
        end

        if isfield(tmp_struct, 'Date')
            flags(2) = OBJ(i).filter_by_date(tmp_struct.Date);
        end

        chks(j) = all(flags);
    end

    hit = min(find(chks));

    if any(chks)

        if USE_SESSION
            OBJ(i).metadata.groups = sprintf('%s_%s', lower(OBJ(i).metadata.extract.SessionName), lower(metadata{hit}.Group));
        else
            OBJ(i).metadata.groups = sprintf('%s', lower(metadata{hit}.Group));
        end

    else
        OBJ(i).metadata.groups = DEFAULT_NAME;
    end

    IDX(i) = any(chks);

end

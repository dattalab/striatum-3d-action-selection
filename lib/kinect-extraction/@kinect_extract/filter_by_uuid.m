function IDX = filter_by_uuid(OBJ, UUID)
%
%
uuids = cell(1, length(OBJ));

for i = 1:length(OBJ)
    uuids{i} = OBJ(i).metadata.uuid;
end

IDX = false(size(uuids));

if iscell(UUID)

    for i = 1:length(UUID)
        IDX = IDX | strcmp(uuids, UUID{i});
    end

else
    IDX = strcmp(uuids, UUID);
end

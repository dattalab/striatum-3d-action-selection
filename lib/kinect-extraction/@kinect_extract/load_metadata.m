function load_metadata(OBJ)
%
%
%
%
%

for i = 1:length(OBJ)
    OBJ(i).metadata.extract = loadjson(OBJ(i).files.metadata{1});
    OBJ(i).metadata.datenum = datenum(OBJ(i).metadata.extract.StartTime, 'yyyy-mm-ddTHH:MM:SS');
end

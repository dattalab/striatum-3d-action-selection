function load_metadata(OBJ, JSONFILE)
%
%
%

tmp = loadjson(JSONFILE);
OBJ.metadata.mouse = [tmp{:}];

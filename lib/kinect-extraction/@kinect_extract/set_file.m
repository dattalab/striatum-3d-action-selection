function set_file(OBJ, FILENAME, FILE);
% Change one of the files, ensure the user doesn't do anything fishy
%

for i = 1:length(OBJ)
    valid_files = fieldnames(OBJ(i).files);

    if any(strcmp(FILENAME, valid_files))
        OBJ(i).files.(FILENAME){1} = FILE;
        OBJ(i).files.(FILENAME){2} = exist(OBJ(i).files.(FILENAME){1}, 'file');
    end

end

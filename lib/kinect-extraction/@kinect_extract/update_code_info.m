function update_code_info(OBJ);
% Prints out details from the current repository.
%

for i = 1:length(OBJ)
    code_tmp = mfilename('fullpath');
    [code_pathname, code_filename, code_ext] = fileparts(code_tmp);
    OBJ(i).metadata.code_ver = getGitInfo(fullfile(code_pathname, '..'));
end

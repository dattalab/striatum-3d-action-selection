function [IS_MOVIE FILENAMES] = is_movie_file(DIR)
% checks for movie file in specific DIR
%
%
%
%

tmp = dir(DIR);

if isempty(tmp)
    IS_MOVIE = false;
    FILENAMES = [];
    return;
end

if ~isfield(tmp(1), 'folder')
    [tmp_dir, ~, ~] = fileparts(DIR);
else
    tmp_dir = tmp(1).folder;
end

tmp = {tmp(:).name};
idx = cellfun(@(x) ~isempty(x), regexp(tmp, '.*(mp4|avi|mov|mj2)'));
IS_MOVIE = any(idx);
FILENAMES = tmp(idx);

% put the full path back in

FILENAMES = cellfun(@(x) fullfile(tmp_dir, x), FILENAMES, 'UniformOutput', false);

function FLAGS = kinect_matfile_checkflags(FILE, varargin)
%
%
%
%
%

FLAGS = false(1, length(varargin));

ismemmap = false;

if strcmp(class(FILE), 'matlab.io.MatFile')
    ismemmap = true;
end

if ~ismemmap & exist(FILE, 'file') == 2
    m = matfile(FILE);
elseif ismemmap
    m = FILE;
else
    return;
end

fileinfo = whos(m);
varnames = {fileinfo(:).name};

for i = 1:length(varargin)
    idx = strcmp(varargin{i}, varnames);

    if any(idx) & strcmp(fileinfo(idx).class, 'logical')
        FLAGS(i) = m.(varargin{i});
    elseif any(idx)
        FLAGS(i) = true;
    end

end

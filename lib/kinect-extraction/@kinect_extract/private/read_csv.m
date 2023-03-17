function DATA = kinect_read_csv(FILENAME, DELIM, HEADER)
%
%
%

if nargin < 1 | isempty(FILENAME)
    [filename, pathname] = uigetfile('*.txt');
    FILENAME = fullfile(pathname, filename);
end

if nargin < 2 | isempty(DELIM)
    DELIM = ' ';
end

if nargin < 3 | isempty(HEADER)
    HEADER = 0;
end

fid = fopen(FILENAME, 'r');

for i = 1:HEADER
    data = fgetl(fid);
end

% cycle through header
data = fgetl(fid);

% get number of columns
tmp = regexp(data, DELIM, 'split');
ncols = length(tmp);

nlines = 0;

while ~feof(fid)
    fgetl(fid);
    nlines = nlines + 1;
end

nlines = nlines + 1;
fclose(fid);
fprintf('Found %i lines\n', nlines);

fopen(FILENAME, 'r');

for i = 1:HEADER
    data = fgetl(fid);
end

DATA = zeros(nlines, ncols);

% now read through for real
for i = 1:nlines
    raw = fgetl(fid);
    DATA(i, :) = sscanf(raw, ['%f' DELIM]);
end

fclose(fid);

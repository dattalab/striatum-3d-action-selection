function [DATA, TIMESTAMPS] = load_nidaq(OBJ, pth)
%
%

nchannels = OBJ.metadata.extract.NidaqChannels;
datatype = lower(regexprep(OBJ.metadata.extract.NidaqDataType, '[^a-zA-Z]', ''));

if nargin > 1
    fid = fopen(pth, 'rb');
else
    fid = fopen(OBJ.files.nidaq{1}, 'rb');
end

DATA = fread(fid, [nchannels + 1 inf], datatype)';
TIMESTAMPS = DATA(:, end);
DATA = DATA(:, 1:end - 1);
fclose(fid);

end % function

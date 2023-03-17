function FILT_DATA = bandpass(DATA, FC, BW, FS, ORDER, TYPE, RIPPLE, ATTENUATION)
%
%
%

if nargin < 8
    ATTENUATION = 40;
end

if nargin < 7
    RIPPLE = .2;
end

if nargin < 6
    TYPE = 'b';
end

if nargin < 5
    ORDER = 3;
end

nans = isnan(DATA);
DATA(nans) = 0;

switch lower(TYPE(1))
    case 'b'
        [b, a] = butter(ORDER, [FC - BW / 2 FC + BW / 2] / (FS / 2), 'bandpass');
    case 'e'
        [b, a] = ellip(ORDER, RIPPLE, ATTENUATION, [FC - BW / 2 FC + BW / 2] / (FS / 2), 'bandpass');
    otherwise
        error('Did not understand filter type');
end

FILT_DATA = filtfilt(b, a, DATA);
FILT_DATA(nans) = nan;

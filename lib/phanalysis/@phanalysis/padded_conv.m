function SIGNAL = padded_conv(DATA, KERNEL, METHOD)
%
%
%

if nargin < 3
    METHOD = 'r'; % by default, reflect values
end

if ~isvector(DATA)
    error('Data must be 1d');
else
    DATA = DATA(:);
end

len = length(KERNEL);
data_len = length(DATA);

switch lower(METHOD(1))

    case 'r'

        DATA = [DATA(len:-1:1); DATA; DATA(data_len:-1:data_len - (len - 1))];

    case 's'

        DATA = [ones(len, 1) * DATA(1); DATA; ones(len, 1) * DATA(data_len)];

    otherwise
end

SIGNAL = conv(DATA, KERNEL, 'same');

% chop away ze pads

SIGNAL = SIGNAL(len + 1:len + data_len);

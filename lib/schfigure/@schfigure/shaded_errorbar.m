function H = shaded_errorbar(X, Y, FACECOLOR, EDGECOLOR, METHOD)
%
%
%
%
%
%

if nargin < 5
    METHOD = 'patch';
else
    METHOD = 'fill';
end

if nargin < 4 | isempty(EDGECOLOR)
    EDGECOLOR = 'k';
end

if nargin < 3 | isempty(FACECOLOR)
    FACECOLOR = [.4 .4 .4];
end

if nargin < 1 | isempty(X)
    X = 1:numel(Y);
end

xdata = X(:)';

% take care of nans

todel = any(isnan(Y) | isnan(Y));

xdata(todel) = [];
Y(:, todel) = [];

xdata = [xdata fliplr(xdata)];
ydata = [Y(1, :) fliplr(Y(2, :))];

if strcmp(lower(METHOD(1)), 'p')
    H = patch(xdata, ydata, 1, 'facecolor', FACECOLOR, 'edgecolor', EDGECOLOR);
else
    H = fill(xdata, ydata, 1, 'facecolor', FACECOLOR, 'edgecolor', EDGECOLOR);
end

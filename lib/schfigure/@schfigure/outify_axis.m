function outify_axis(AX, TICK_LENGTH)
%
%
%

if nargin < 2
    TICK_LENGTH = [.025 .025];
end

if nargin < 1 | isempty(AX)
    AX = findall(gcf, 'type', 'axes');
end

for i = 1:length(AX)
    AX(i).TickDir = 'out';
    AX(i).TickLength = TICK_LENGTH;
end

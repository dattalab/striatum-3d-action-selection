function MASK = kinect_ellipse_select(CDATA, STRING)
%
%
%
% TODO: if MOVIE, add slider, etc.

if nargin < 2
    STRING = [];
end

clipping = [5 95];

% make figure, display projection, choose ROI, export as X Y coords and binary mask
clips = prctile(CDATA(CDATA > 0), clipping);
if clips(2) > 80, clips(2) = 80; end
CDATA(CDATA < clips(1)) = clips(1);
CDATA = CDATA - clips(1);
CDATA(CDATA > clips(2) - clips(1)) = clips(2) - clips(1);

select_fig = figure('MenuBar', 'none', 'Toolbar', 'none', ...
    'NumberTitle', 'off', 'Name', 'Ellipse Select Tool', 'Color', [0 0 0]);

ax = axes('position', [.1 .1 .8 .8]);
imagesc(CDATA, 'parent', ax);
colormap(jet);
%colorbar();
title([STRING], 'color', [1 1 1]);
caxis([0 clips(2) - clips(1)])
axis off;

h = imellipse;
position = wait(h);
[m, n] = size(CDATA);
MASK = poly2mask(position(:, 1), position(:, 2), m, n);
close([select_fig]);

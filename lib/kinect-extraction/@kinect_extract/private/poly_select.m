function [X Y MASK IM_ROI] = kinect_poly_select(CDATA)
%
%
%
% TODO: if MOVIE, add slider, etc.

% make figure, display projection, choose ROI, export as X Y coords and binary mask

select_fig = figure();
imagesc(CDATA);
[IM_ROI X Y] = roipoly();
close([select_fig]);

[m, n] = size(CDATA);
MASK = poly2mask(X, Y, m, n);

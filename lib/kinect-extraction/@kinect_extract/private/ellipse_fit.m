function [X Y] = kinect_ellipse_fit(STRUCT, WEIGHTED_CENTROID)
%
%

% given regionprops, return points from the corresponding ellipse
% convert to radians

ang = -STRUCT.Orientation * pi / 180;

t = linspace(0, pi * 2, 15);

x = STRUCT.MajorAxisLength / 2 * cos(t);
y = STRUCT.MinorAxisLength / 2 * sin(t);

X = x * cos(ang) - y * sin(ang) + STRUCT.Centroid(1);
Y = x * sin(ang) + y * cos(ang) + STRUCT.Centroid(2);

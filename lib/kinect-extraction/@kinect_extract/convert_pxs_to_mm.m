function [XW, YW] = convert_pxs_to_mm(X, Y, ZW)
% Converts x,y points to points in mm at a given depth
%

if nargin < 3 | isempty(ZW)
    ZW = 673.1; % our default depth has been 29.5 inches, or 673 mm
end

% need real-world depth of the arena, typically 29.5 inches or 749 mm

% http://stackoverflow.com/questions/17832238/kinect-intrinsic-parameters-from-field-of-view/18199938#18199938
% http://www.imaginativeuniversal.com/blog/post/2014/03/05/quick-reference-kinect-1-vs-kinect-2.aspx

% adjust x,y so that 0,0 is the origin

X = X - 512/2;
Y = Y - 424/2;

fh = 424 / (2 * tand(60/2));
fw = 512 / (2 * tand(70/2));

XW = ZW * X / fw;
YW = ZW * Y / fh;

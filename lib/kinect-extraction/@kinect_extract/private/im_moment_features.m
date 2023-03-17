function FEATURES = im_moment_features(IM, ISLIST)
%
%
%
%
%

if nargin < 2
    ISLIST = false;
end

% use central normalized moments to get principal axes and orientation
% also computing skewness, may help resolve pi flips

% so many different definitions, let's consider wikipedia the canon ATM
% also good reference: http://www.via.cornell.edu/ece547/text/survey.pdf

% if im is logical, convert to coordinates

m00 = im_moment(IM, 0, 0, ISLIST);
m10 = im_moment(IM, 1, 0, ISLIST);
m01 = im_moment(IM, 0, 1, ISLIST);

xbar = m10 / m00;
ybar = m01 / m00;

mu20 = im_moment_cent(IM, xbar, ybar, 2, 0, ISLIST);
mu02 = im_moment_cent(IM, xbar, ybar, 0, 2, ISLIST);
mu11 = im_moment_cent(IM, xbar, ybar, 1, 1, ISLIST);
mu03 = im_moment_cent(IM, xbar, ybar, 3, 0, ISLIST);
mu30 = im_moment_cent(IM, xbar, ybar, 0, 3, ISLIST);
mu00 = im_moment_cent(IM, xbar, ybar, 0, 0, ISLIST);

num = 2 * mu11;
den = mu20 - mu02;

FEATURES.Orientation =- .5 * atan2(num, den) * 180 / pi; % minus to keep consistent w/ regionprops implementation
FEATURES.Skewness = [mu30 mu03];
FEATURES.Centroid = [xbar ybar];
common = sqrt(4 * mu11 ^ 2 + (mu20 - mu02) ^ 2);

FEATURES.AxisLength = [2 * sqrt(2) * sqrt((mu20 + mu02 + common) / mu00) 2 * sqrt(2) * sqrt((mu20 + mu02 - common) / mu00)];
FEATURES.Eccentricity = 2 * sqrt((FEATURES.AxisLength(1) / 2) ^ 2 - (FEATURES.AxisLength(2) / 2) ^ 2) / FEATURES.AxisLength(1);

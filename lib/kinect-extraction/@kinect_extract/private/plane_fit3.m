function PLANE = plane_fit3(POINTS)
% given 3 points, fit a plane, used in RANSAC plane fit
%
%

% liberally cribbed from MATLAB's pcplanefit

a = POINTS(2, :) - POINTS(1, :);
b = POINTS(3, :) - POINTS(1, :);
% Cross product
normal = [a(2) .* b(3) - a(3) .* b(2), ...
              a(3) .* b(1) - a(1) .* b(3), ...
              a(1) .* b(2) - a(2) .* b(1)];

denom = sum(normal .^ 2);

if denom < eps(class(POINTS))
    PLANE = [];
else
    normal = normal / sqrt(denom);
    d = -POINTS(1, :) * normal';
    PLANE = [normal d];
end

function DATA = clean_up_timeseries(DATA, MAX_DIST)
%
%
%
%

if nargin < 2 | isempty(MAX_DIST)
    MAX_DIST = 3;
end

% interpolate all nans that are close enough to a good frame

nans = isnan(DATA(:, 1));
not_nans = ~nans;

nans = find(nans);
not_nans = find(not_nans);

dist = zeros(length(nans), 1);

for i = 1:length(nans)
    dist(i) = min(abs(nans(i) - not_nans));
end

to_correct = nans(dist <= MAX_DIST);

% interpolate to_correct w/ not_nan data

if sum(to_correct) > 0

    for i = 1:size(DATA, 2)
        DATA(to_correct, i) = interp1(not_nans, DATA(not_nans, i), to_correct, 'spline');
    end

end

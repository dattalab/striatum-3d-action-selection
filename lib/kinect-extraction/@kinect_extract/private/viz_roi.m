function IM_ROI = viz_roi(IMAGE, ROI, RANGE, COLORMAP)
% Takes an image and creates a simple visualization for ROI
%
%

if nargin < 4 | isempty(COLORMAP)
    COLORMAP = jet(256);
end

if nargin < 3 | isempty(RANGE)
    RANGE = prctile(IMAGE(:), [0 100]);
end

if ~isa(IMAGE, 'single')
    IMAGE = single(IMAGE);
end

IMAGE = IMAGE - RANGE(1);
IMAGE(IMAGE < 0) = 0;
IMAGE(IMAGE > diff(RANGE)) = diff(RANGE);
IMAGE = IMAGE ./ diff(RANGE);
IMAGE = round(IMAGE .* size(COLORMAP, 1));
IM_ROI = ind2rgb(IMAGE, COLORMAP);

if ~isempty(ROI)
    ROI = repmat(ROI, [1 1 3]);
    roi_idx = ROI > 0;
    IM_ROI(~ROI) = .75;
end

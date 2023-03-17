function DIST = get_average_mouse_distance(OBJ)
%
%
%
%

num_ims = length(OBJ);
output_view = imref2d(OBJ(1).options.common.box_size);

DIST.no_transform = nan(num_ims);
DIST.transform = nan(num_ims);
DIST.width = nan(num_ims, 1);
DIST.height = nan(num_ims, 1);

for i = 1:num_ims

    for j = 1:num_ims

        im1 = OBJ(i).average_image;
        im2 = OBJ(j).average_image;

        DIST.no_transform(i, j) = norm(im1 - im2);

        if ~isempty(OBJ(i).transform)
            im1 = imwarp(im1, OBJ(i).transform, 'OutputView', output_view);
        end

        if ~isempty(OBJ(j).transform)
            im2 = imwarp(im2, OBJ(j).transform, 'OutputView', output_view);
        end

        DIST.transform(i, j) = norm(im1 - im2);

    end

    im1 = OBJ(i).average_image;

    if ~isempty(OBJ(i).transform)
        im1 = imwarp(im1, OBJ(i).transform, 'OutputView', output_view);
    end

    [r, c] = find(im1 > .6);
    DIST.width(i) = range(c);
    DIST.height(i) = range(r);

end

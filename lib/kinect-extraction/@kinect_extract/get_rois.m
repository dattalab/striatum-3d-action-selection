function get_rois(OBJ)
% Simple function to get and save an ROI without performing the full extraction
%

for i = 1:length(OBJ)

    opts = mergestruct(OBJ(i).options.common, OBJ(i).options.roi);

    if ~isfield(OBJ(i).metadata, 'extract')
        fprintf('Loading metadata...\n');
        OBJ(i).load_metadata;
    end

    if OBJ(i).files.roi{2}
        fprintf('ROI file already exists\n');
        continue;
    else
        fprintf('Getting ROI(s) for %s\n', OBJ(i).working_dir);
    end

    frame_mmap = memmapfile(OBJ(i).files.raw_data{1}, 'format', 'uint16');

    nframes = length(frame_mmap.Data) / prod(OBJ(i).metadata.extract.DepthResolution);
    width = OBJ(i).metadata.extract.DepthResolution(1);
    height = OBJ(i).metadata.extract.DepthResolution(2);
    sel_frames = min(nframes, OBJ(i).options.extract.sel_frames);

    % rotate the image and mirror flip

    pick_frames = int16(imrotate(reshape(frame_mmap.Data(1:width * height * sel_frames), [width height sel_frames]), -90));

    % auto_roi:  at this point simply average across sel_frames, apply a minimum filter
    % then use threshold criteria, fit a plane, and use all points within 50 mm
    %
    % finally, get connected components and take the largest component (or the component)
    % connected to the center, apply this mask and use some simple criteria to get us to the mouse

    % remove background from the frames we want to use

    [pick_frames, bg_im] = bg_remove(pick_frames);
    im_debug = [];

    switch lower(opts.method(1))

        case 'a'

            [xx, yy] = meshgrid(1:width, 1:height);
            all_points = single([xx(:) yy(:) bg_im(:)]);

            % fit a plane to the background image w/ RANSAC

            fprintf('Fitting plane to background image...\n');
            roi_plane = plane_ransac(single(bg_im), opts.depth_range, opts.ransac_iters, opts.noise_tol);

            % get the distance between all points and the plane

            all_points_dist = abs((all_points * roi_plane(1:3)' + roi_plane(4)));

            % our extraction mask is all the points<N mm from the plane

            fprintf('Processing extraction and tracking masks...\n');
            extract_mask = int16(reshape(all_points_dist < opts.noise_tol, height, width));
            extraction_roi = extract_mask;

            % dilate the extraction mask to account for walls

            cc = bwconncomp(extraction_roi);
            im_props = regionprops(cc, 'Centroid', 'Area', 'Solidity', 'PixelList');

            % get the distance to the center of the image

            im_center = [width height] / 2;

            siz = cat(1, im_props(:).Area);

            to_del = siz < opts.min_area;

            siz(to_del) = [];
            im_props(to_del) = [];
            cc.PixelIdxList(to_del) = [];

            dist = zeros(1, length(im_props));
            sol = cat(1, im_props(:).Solidity);

            for j = 1:length(im_props)
                tmp = sqrt((im_props(j).PixelList(:, 1) - im_center(1)) .^ 2 + ...
                    (im_props(j).PixelList(:, 2) - im_center(2)) .^ 2);
                dist(j) = max(tmp);
            end

            ranking = zeros(3, length(im_props));

            siz_sorted = sort(siz, 'descend');
            ext_sorted = sort(sol, 'descend');
            dist_sorted = sort(dist, 'ascend');

            [~, ranking(1, :)] = ismember(siz, siz_sorted);
            [~, ranking(2, :)] = ismember(sol, ext_sorted);
            [~, ranking(3, :)] = ismember(dist, dist_sorted);

            weights = [.3 .3 .4];
            [~, idx] = min(mean(ranking .* repmat(weights(:), [1 length(im_props)])));

            if length(idx) > 1
                [~, idx2] = min(dist(idx));
                idx = idx(idx2);
            end

            extraction_roi = false(size(extraction_roi));
            extraction_roi(cc.PixelIdxList{idx}) = 1;

            siz_debug = zeros(size(extraction_roi));
            sol_debug = zeros(size(extraction_roi));
            dist_debug = zeros(size(extraction_roi));

            for j = 1:length(cc.PixelIdxList)
                siz_debug(cc.PixelIdxList{j}) = siz(j) ./ max(siz);
                sol_debug(cc.PixelIdxList{j}) = sol(j) ./ max(sol);
                dist_debug(cc.PixelIdxList{j}) = dist(j) ./ max(dist);
            end

            im_debug.siz = viz_roi(siz_debug, [], [0 1]);
            im_debug.sol = viz_roi(sol_debug, [], [0 1]);
            im_debug.dist = viz_roi(dist_debug, [], [0 1]);

            debug_names = fieldnames(im_debug);

            for j = 1:length(debug_names)
                imwrite(im_debug.(debug_names{j}), fullfile(OBJ(i).working_dir, sprintf('roi_debug_%s.tiff', debug_names{j})));
            end

            tracking_roi = pick_frames(:, :, 1) .* cast(extraction_roi, 'like', pick_frames(:, :, 1));
            tracking_roi(tracking_roi < OBJ(i).options.roi.mouse_range(1)) = 0;
            tracking_roi(tracking_roi > OBJ(i).options.roi.mouse_range(2)) = 0;

            % the mouse is the largest object after bground subtraction and morphological
            % opening (can be conservative w/ the opening typically)

            cc = bwconncomp(tracking_roi);
            len = cellfun(@length, cc.PixelIdxList);

            % take the largest connected object

            [~, idx] = max(len);
            tracking_roi = false(size(tracking_roi));
            tracking_roi(cc.PixelIdxList{idx}) = 1;

            % now dilate everything

            if opts.dilate_size > 0
                extraction_roi = imdilate(extraction_roi, strel(opts.dilate_strel, opts.dilate_size));
            end

            if opts.open_size > 0
                tracking_roi = imopen(tracking_roi, strel(opts.open_strel, opts.open_size));
            end

            % Store the plane for downstream calculations of actual distance (requires
            % an estimate of real-world distance from camera)

        case 'm'

            display_frames = 1:sel_frames;
            extraction_roi = ellipse_select(mean(pick_frames(:, :, display_frames), 3), 'Select extraction ROI');
            tracking_roi = ellipse_select(double(pick_frames(:, :, 1)), 'Select mouse ROI');

        otherwise
            error('Did not understand roi method %s', opts.method);
    end

    % write out ROIs using imwrite in the proc directory for the user to verify

    im_extraction = viz_roi(pick_frames(:, :, 1), extraction_roi, [0 75]);
    im_tracking = viz_roi(pick_frames(:, :, 1), tracking_roi, [0 75]);
    im_full = viz_roi(pick_frames(:, :, 1), [], [0 75]);

    fprintf('Saving ROI(s)...\n');
    imwrite(im_extraction, fullfile(OBJ(i).working_dir, ['roi_extraction.tiff']));
    imwrite(im_tracking, fullfile(OBJ(i).working_dir, ['roi_tracking.tiff']));
    imwrite(im_full, fullfile(OBJ(i).working_dir, ['roi_firstframe.tiff']));

    if OBJ(i).has_timer > 0

        % filter for the LED at the appropriate frequency

        pick_frames = reshape(double(pick_frames), height * width, []);
        [b, a] = ellip(5, .2, 40, [max(OBJ(i).has_timer - .5, .05) OBJ(i).has_timer + .5] / (OBJ(i).options.common.camera_fs / 2), 'bandpass');

        pick_frames = pick_frames';
        pick_frames = filtfilt(b, a, zscore(pick_frames));
        pick_frames = reshape(pick_frames', height, width, []);

        % grab median ^2 value from the filter, then smooth a little bit in space

        timer_im = imgaussfilt(median(pick_frames .^ 2, 3), 1.5);
        timer_roi = timer_im > .15;

        im_timer = viz_roi(ones(size(timer_roi)), timer_roi, [0 1]);
        imwrite(im_timer, fullfile(OBJ(i).working_dir, ['roi_timer.tiff']));

    else

        timer_roi = false(height, width);

    end

    save(OBJ(i).files.roi{1}, 'extraction_roi', 'tracking_roi', 'timer_roi');

end

OBJ.update_status;

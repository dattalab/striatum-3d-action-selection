function get_mouse_transform(OBJ, REFID, TFORMID)
%
%
%
%
%

if nargin < 3
    TFORMID = {};
end

% get average from our reference

mouse_ids = {OBJ.mouse_id};

if isempty(TFORMID)
    TFORMID = mouse_ids;
    TFORMID(strcmp(TFORMID, REFID)) = [];
end

upd = kinect_extract.proc_timer(length(TFORMID));

for i = 1:length(TFORMID)
    tform_mice = find(OBJ.filter_by_mouse(TFORMID{i}));

    % get average weighted by nframes

    ref_ave = OBJ.compute_weighted_mouse_average(REFID);
    tform_ave = OBJ.compute_weighted_mouse_average(TFORMID{i});

    [regconfig, metric] = imregconfig('monomodal');
    tform = imregtform(int16(tform_ave > 15), int16(ref_ave > 15), 'affine', regconfig, metric);

    for j = 1:length(tform_mice)
        OBJ(tform_mice(j)).transform = tform;
    end

    upd(i);

end

OBJ.update_status;

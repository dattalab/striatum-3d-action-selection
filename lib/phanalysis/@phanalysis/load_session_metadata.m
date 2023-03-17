function load_session_metadata(OBJ, KINECT)
%
%
%
%

OBJ.session = struct();
is_mouse_meta = false;

if isfield(OBJ.metadata, 'mouse') & isstruct(OBJ.metadata.mouse) & isfield(OBJ.metadata.mouse, 'Name')
    mouse_ids = lower({OBJ.metadata.mouse(:).Name});
    is_mouse_meta = true;
end

for i = 1:length(KINECT)

    OBJ.session(i).session_name = KINECT(i).metadata.extract.SessionName;
    OBJ.session(i).mouse_id = KINECT(i).mouse_id;
    OBJ.session(i).datenum = KINECT(i).metadata.datenum;
    OBJ.session(i).uuid = KINECT(i).metadata.uuid;
    OBJ.session(i).group = KINECT(i).metadata.groups;

    switch lower(OBJ.data_type(1))
        case 'p'
            OBJ.session(i).use_gcamp = false;
            OBJ.session(i).use_rcamp = false;

            if ~isempty(OBJ.photometry)
                OBJ.session(i).has_photometry = length(OBJ.photometry(i).traces) > 0;
            else
                OBJ.session(i).has_photometry = false;
            end

        case 'i'
            OBJ.session(i).has_imaging = length(OBJ.imaging(i).traces) > 0;
    end

    if is_mouse_meta
        match_idx = strcmpi(mouse_ids, OBJ.session(i).mouse_id);
        OBJ.session(i).metadata = OBJ.metadata.mouse(match_idx);
    else
        OBJ.session(i).metadata = struct();
    end

end

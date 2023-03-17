function PHOT_OBJ = get_photometry(OBJ, TDT, FORCE, STORE, KINECT_TIME, OPTIONS)
%
%
%

if nargin < 6 | isempty(OPTIONS)
    OPTIONS = {};
end

if nargin < 5 | isempty(KINECT_TIME)
    KINECT_TIME = true;
end

if nargin < 4 | isempty(STORE)
    STORE = true;
end

if nargin < 3 | isempty(FORCE)
    FORCE = false;
end

if nargin < 2 | isempty(TDT)
    TDT = false;
end

for i = length(OBJ):-1:1

    if (isfield(OBJ(i).neural_data, 'photometry') & ~FORCE) & isa(OBJ(i).neural_data.photometry, 'hifiber')
        PHOT_OBJ(i) = OBJ(i).neural_data.photometry;
        continue;
    elseif (isfield(OBJ(i).neural_data, 'photometry') & ~FORCE) & ~isa(OBJ(i).neural_data.photometry, 'hifiber')
        continue;
    else
        PHOT_OBJ(i) = hifiber;
    end

    if ~isfield(OBJ(i).metadata, 'nframes')
        OBJ(i).load_timestamps;
    end

    if ~isfield(OBJ(i).metadata, 'extract')
        OBJ(i).load_metadata;
    end

    if TDT

        fprintf('Retrieving data for object %i/%i\n', i, length(OBJ));

        [tdt_data, tdt_ts] = OBJ(i).load_tdt;

        if isempty(tdt_data)
            fprintf('No photometry data for object %i, continuing\n', i);
            OBJ(i).neural_data.photometry = hifiber;
            continue;
        end

        tdt_sync = {};

        lens = cellfun(@(x) size(x, 1), tdt_data);
        tdt_data(lens == 0) = [];
        tdt_ts(lens == 0) = [];

        for j = 1:length(tdt_data)
            tdt_sync{j} = tdt_data{j}(:, end);
        end

        status = OBJ(i).load_tdt_timestamps(1, tdt_sync);

        if ~status
            fprintf('Error loading timestamps for object %i, continuing\n', i);
            OBJ(i).neural_data.photometry = hifiber;
            continue;
        end

        if length(tdt_data) > 1
            lens = cellfun(@(x) size(x, 1), tdt_data);
            [~, idx] = max(lens);
            use_tdt = idx;
        else
            use_tdt = 1;
        end

        % check for uv reference version

        uv_check = ~isempty(regexp(OBJ(i).metadata.tdt{use_tdt}.settings.circuit_file, 'reference_v1.rcx$'));

        if uv_check

            fprintf('Found UV reference session for object %i\n', i);
            PHOT_OBJ(i) = hifiber(tdt_data{use_tdt}(:, [1 3 5]), OBJ(i).timestamps.tdt{use_tdt});

            for j = 1:2:length(OPTIONS)
                PHOT_OBJ(i).set_option(OPTIONS{j}, OPTIONS{j + 1});
            end

            PHOT_OBJ(i).set_option('rereference_method', 'v');
            PHOT_OBJ(i).set_metadata_tdt(OBJ(i).metadata.tdt{use_tdt});
            PHOT_OBJ(i).set_modulation_frequency;
            PHOT_OBJ(i).detect_references;
            PHOT_OBJ(i).demodulate;
            PHOT_OBJ(i).downsample;
            PHOT_OBJ(i).get_baseline;
            PHOT_OBJ(i).subtract_baseline;
            PHOT_OBJ(i).get_dff;
            PHOT_OBJ(i).set_reference_channel(1, 3);
            PHOT_OBJ(i).set_reference_channel(5, 3);
            PHOT_OBJ(i).rereference;

        else
            PHOT_OBJ(i) = hifiber(tdt_data{use_tdt}(:, [1 4]), OBJ(i).timestamps.tdt{use_tdt});

            for j = 1:2:length(OPTIONS)
                PHOT_OBJ(i).set_option(OPTIONS{j}, OPTIONS{j + 1});
            end

            PHOT_OBJ(i).set_metadata_tdt(OBJ(i).metadata.tdt{use_tdt});
            PHOT_OBJ(i).set_modulation_frequency;
            PHOT_OBJ(i).detect_references;
            PHOT_OBJ(i).demodulate;
            PHOT_OBJ(i).downsample;
            PHOT_OBJ(i).get_baseline;
            PHOT_OBJ(i).subtract_baseline;
            PHOT_OBJ(i).get_dff;
            PHOT_OBJ(i).set_reference_channel(1, 3);
            PHOT_OBJ(i).set_reference_channel(4, 3);
            PHOT_OBJ(i).rereference;
        end

    else

        if OBJ(i).files.nidaq{2}
            [data, ts] = OBJ(i).load_nidaq;
            PHOT_OBJ(i) = hifiber(data, ts, OBJ(i).metadata.extract.NidaqChannelNames);
            OBJ(i).neural_data.photometry = PHOT_OBJ(i);
        end

    end

    if KINECT_TIME
        PHOT_OBJ(i).change_timebase(OBJ(i).timestamps.depth(:, 2));
    end

    if STORE
        OBJ(i).neural_data.photometry = PHOT_OBJ(i);
    end

end

OBJ.update_status;

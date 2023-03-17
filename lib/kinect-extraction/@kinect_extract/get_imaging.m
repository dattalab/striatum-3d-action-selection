function CA_OBJ = get_imaging(OBJ, INCLUDE_EVENT_TIMES, FORCE, USE_NEW)
%
%
%
%
%

if nargin < 2 | isempty(INCLUDE_EVENT_TIMES)
    INCLUDE_EVENT_TIMES = true;
end

if nargin < 3
    FORCE = false;
end

if nargin < 4
    USE_NEW = true;
end

CA_OBJ = hifiber.empty(0, length(OBJ));

for i = length(OBJ):-1:1

    if isfield(OBJ(i).neural_data, 'ca') & (isa(OBJ(i).neural_data.ca, 'hifiber') ...
            & ~isempty(OBJ(i).neural_data.ca.traces)) & ~FORCE
        CA_OBJ(i) = OBJ(i).neural_data.ca;
        continue;
    end

    if ((OBJ(i).files.ca_data{2}) | (USE_NEW & OBJ(i).files.ca_data_new{2}))

        OBJ(i).load_inscopix_timestamps;
        OBJ(i).metadata.inscopix = struct();

        if isempty(OBJ(i).timestamps.inscopix)
            continue;
        end

        if USE_NEW & OBJ(i).files.ca_data_new{2}
            fprintf('Loading cnmf-e file %s\n', OBJ(i).files.ca_data_new{1});
            load(OBJ(i).files.ca_data_new{1}, 'neuron');
        else
            fprintf('Loading cnmf-e file %s\n', OBJ(i).files.ca_data{1});
            load(OBJ(i).files.ca_data{1}, 'neuron');
        end

        [nrois, ninscopix_frames] = size(neuron.C);

        OBJ(i).metadata.inscopix.nframes = ninscopix_frames;
        OBJ(i).metadata.inscopix.sync_nframes = max(OBJ(i).timestamps.inscopix);
        OBJ(i).metadata.inscopix.fs = neuron.Fs;

        if max(OBJ(i).timestamps.inscopix) < ninscopix_frames
            fprintf('More data frames than sync frames...\n');
            OBJ(i).metadata.inscopix.align_status = 2;
        elseif max(OBJ(i).timestamps.inscopix) == ninscopix_frames
            fprintf('Frames match in sync and data...\n');
            OBJ(i).metadata.inscopix.align_status = 1;
        else
            fprintf('Fewer data frames than sync frames...\n');
            OBJ(i).metadata.inscopix.align_status = 0;
        end

        CA_OBJ(i) = hifiber(full(neuron.C_raw)', [1:size(neuron.C, 2)] / neuron.Fs, neuron.Fs);

        %[nrows,ncols]=size(neuron.Cn);

        nrows = neuron.options.d1;
        ncols = neuron.options.d2;

        CA_OBJ(i).set_option('change_method', 'bin');
        CA_OBJ(i).change_timebase(OBJ(i).timestamps.inscopix / neuron.Fs);

        % get all the relevant metadata and image data we might want

        CA_OBJ(i).user_data.corr_im = neuron.Cn;
        CA_OBJ(i).user_data.coordinates = neuron.Coor';

        for j = 1:nrois
            CA_OBJ(i).traces(j).cell_mask = reshape(neuron.A(:, j), nrows, ncols);
        end

        if INCLUDE_EVENT_TIMES
            tmp = hifiber(full(neuron.S)', [1:size(neuron.C, 2)] / neuron.Fs, neuron.Fs);
            tmp.set_option('change_method', 'bin');
            tmp.change_timebase(OBJ(i).timestamps.inscopix / neuron.Fs);

            for j = 1:nrois
                CA_OBJ(i).traces(j).deconv = tmp.traces(j).raw;
            end

        end

    end

    OBJ(i).neural_data.ca = CA_OBJ(i);

end

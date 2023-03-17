function downsample(OBJ)
% downsamples data for downstream processing
%

% anti-alias filtering

valid_types = {'dff', 'raw', 'baseline', 'baseline_rem', 'reref', 'x', 'y'};

fprintf('Downsampling data...\n');

for i = 1:length(OBJ)

    upd = hifiber.proc_timer(length(OBJ(i).traces));

    %[p,q]=rat(OBJ(i).options.new_fs/OBJ(i).metadata.fs);
    nans = isnan(OBJ(i).timestamps);

    for j = 1:length(OBJ(i).traces)

        data_types = fieldnames(OBJ(i).traces(j));

        for k = 1:length(data_types)

            if any(strcmp(data_types{k}, valid_types))

                %OBJ(i).traces(j).(data_types{k})(nans)=nan;
                signal_len = length(OBJ(i).traces(j).(data_types{k}));
                [OBJ(i).traces(j).(data_types{k}), new_ts, b] = resample(OBJ(i).traces(j).(data_types{k}), ...
                    [0:signal_len - 1] / OBJ(i).metadata.fs, OBJ(i).options.new_fs);

                filt_length = numel(b) / OBJ(i).metadata.fs;
                filt_length_res = round(filt_length * OBJ(i).options.new_fs) + 10;

                OBJ(i).traces(j).(data_types{k})(1:filt_length_res) = nan;
                OBJ(i).traces(j).(data_types{k})(end - filt_length_res:end) = nan;

            end

        end

        upd(j);

    end

    if length(OBJ(i).references) > 0
        upd = hifiber.proc_timer(length(OBJ(i).references));
    end

    for j = 1:length(OBJ(i).references)

        data_types = fieldnames(OBJ(i).references(j));

        for k = 1:length(data_types)

            if any(strcmp(data_types{k}, valid_types))

                signal_len = length(OBJ(i).references(j).(data_types{k}));
                [OBJ(i).references(j).(data_types{k}), new_ts, b] = resample(OBJ(i).references(j).(data_types{k}), ...
                    [0:signal_len - 1] / OBJ(i).metadata.fs, OBJ(i).options.new_fs);


                filt_length = numel(b) / OBJ(i).metadata.fs;
                filt_length_res = round(filt_length * OBJ(i).options.new_fs) + 10;

                OBJ(i).references(j).(data_types{k})(1:filt_length_res) = nan;
                OBJ(i).references(j).(data_types{k})(end - filt_length_res:end) = nan;

            end

        end

        upd(j);

    end

    new_timestamps = OBJ(i).timestamps(round(new_ts * OBJ(i).metadata.fs) + 1);
    OBJ(i).timestamps = new_timestamps;
    OBJ(i).metadata.fs = OBJ.options.new_fs;

end

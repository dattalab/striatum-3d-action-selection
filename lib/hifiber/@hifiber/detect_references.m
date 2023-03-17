function detect_references(OBJ)
%
%
%

for i = 1:length(OBJ)

    for j = 1:length(OBJ(i).traces)

        use_data = OBJ(i).traces(j).raw;
        nans = isnan(use_data);

        data_len = length(use_data);
        use_data = use_data(1:min(OBJ(i).options.ref_samples, data_len));

        if OBJ(i).options.mod_bandpass
            use_data = hifiber.bandpass(use_data, OBJ(i).traces(j).mod_freq, ...
                OBJ(i).options.mod_bandpass_bw, OBJ(i).metadata.fs);
        end

        tvec = [0:numel(OBJ(i).traces(j).raw) - 1] / OBJ(i).metadata.fs;

        [params, fit_fun] = hifiber.get_demod_reference(use_data, ...
            tvec(1:length(use_data)), OBJ(i).metadata.fs, OBJ(i).traces(j).mod_freq);

        % reset amplitude to 1 and offset to 0

        OBJ(i).references(j).x = fit_fun([1 params(2:3) 0], tvec);
        OBJ(i).references(j).y = fit_fun([1 params(2) params(3) + pi / 2 0], tvec);
        OBJ(i).references(j).x = OBJ(i).references(j).x(:);
        OBJ(i).references(j).y = OBJ(i).references(j).y(:);

    end

end

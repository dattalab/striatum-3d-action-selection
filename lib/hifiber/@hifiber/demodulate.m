function demodulate(OBJ)
%
%
%

fprintf('Demodulating signals...\n');

for i = 1:length(OBJ)

    demod_samples = round(OBJ(i).metadata.fs * OBJ(i).options.demod_tau);
    demod_hz = 1 / (OBJ(i).options.demod_tau);

    switch lower(OBJ(i).options.demod_filter_type(1))
        case 'e'
            [b, a] = ellip(OBJ(i).options.demod_filter_order, ...
                OBJ(i).options.demod_filter_ripple, OBJ(i).options.demod_filter_attenuation, ...
                [demod_hz] / (OBJ(i).metadata.fs / 2), 'low');
        case 'b'
            [b, a] = butter(OBJ(i).options.demod_filter_order, [demod_hz] / (OBJ(i).metadata.fs / 2), 'low');
    end

    ntraces = length(OBJ(i).traces);
    traces = cat(2, OBJ(i).traces(:).raw);
    mod_freq = cat(2, OBJ(i).traces(:).mod_freq);

    OBJ(i).traces = [];
    OBJ(i).traces = [];

    counter = 1;
    upd = hifiber.proc_timer(ntraces * length(OBJ(i).references));

    for j = 1:ntraces

        % remove traces, and re-populate with the demodded version
        % do all to all, and bandpass as needed...

        for k = 1:length(OBJ(i).references)

            % bandpass for the reference fs

            use_data = hifiber.bandpass(traces(:, j), mod_freq(k), ...
                OBJ(i).options.mod_bandpass_bw, OBJ(i).metadata.fs);

            mult_x = use_data(:) .* OBJ(i).references(k).x(:);
            mult_y = use_data(:) .* OBJ(i).references(k).y(:);

            prod_x = filtfilt(b, a, mult_x);
            prod_y = filtfilt(b, a, mult_y);

            OBJ(i).traces(counter).raw = hypot(prod_x, prod_y);
            OBJ(i).traces(counter).raw(1:(demod_samples + 1)) = nan;
            OBJ(i).traces(counter).raw(end - (demod_samples + 1):end) = nan;

            OBJ(i).traces(counter).type = 'Data';
            OBJ(i).traces(counter).name = sprintf('Ch %i demod ref %i', j, k);

            upd(counter);
            counter = counter + 1;

        end

    end

end

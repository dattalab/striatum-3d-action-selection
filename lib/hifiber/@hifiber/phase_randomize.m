function phase_randomize(OBJ, FIELD)
%
%
%

nsamples = 0;

for i = 1:length(OBJ)

    if length(OBJ(i).traces) > 0

        for j = 1:length(OBJ(i).traces)
            nsamples = nsamples + length(OBJ(i).traces(1).raw);
        end

    end

end

upd = kinect_extract.proc_timer(nsamples);
counter = 0;

for i = 1:length(OBJ)

    for j = 1:length(OBJ(i).traces)

        if isfield(OBJ(i).traces(j), FIELD)

            tmp_fft = fft(OBJ(i).traces(j).(FIELD));
            mag = abs(tmp_fft);
            ang = angle(tmp_fft);
            mag = mag(:);
            ang = ang(:);

            % generate nrands permutations

            [~, permidx] = sort(rand(numel(ang), OBJ(i).options.nrands));

            % synthesize the random signals

            OBJ(i).traces(j).([FIELD '_rnd']) = single(real(ifft(repmat(mag, [1 OBJ(i).options.nrands]) .* exp(1j .* ang(permidx)))));

            counter = counter + length(OBJ(i).traces(j).raw);
            upd(counter);

        end

    end

end

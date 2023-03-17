function get_delta_coeffs(OBJ, FIELD, WIN)
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

            OBJ(i).traces(j).([FIELD '_delta']) = kinect_extract.delta_coefficients(OBJ(i).traces(j).([FIELD]), WIN)';
            counter = counter + length(OBJ(i).traces(j).raw);
            upd(counter);

        end

    end

end

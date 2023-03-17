function get_baseline(OBJ)
%
%

total = OBJ.get_trace_total;

if total == 0
    return;
end

counter = 1;

upd = hifiber.proc_timer(total);

for i = 1:length(OBJ)

    for j = 1:length(OBJ(i).traces)

        use_data = OBJ(i).traces(j).raw;

        nwin = round(OBJ(i).options.baseline_win .* OBJ(i).metadata.fs);

        if mod(nwin, 2) == 0
            nwin = nwin + 1;
        end

        padded_data = [nan(floor(nwin / 2), 1); use_data; nan(floor(nwin / 2), 1)];
        baseline = colfilt(padded_data(:), [nwin 1], [nwin * 2 1], 'sliding', OBJ(i).options.baseline_fcn);

        left_edge = floor(nwin / 2) + 1;
        nsamples = numel(use_data);
        baseline = baseline(left_edge:left_edge + (nsamples - 1));

        if OBJ(i).options.baseline_post_smooth > 0
            baseline = smooth(baseline, OBJ(i).options.baseline_post_smooth * OBJ(i).metadata.fs);
        end

        OBJ(i).traces(j).baseline = baseline(:);
        upd(counter);
        counter = counter + 1;

    end

end

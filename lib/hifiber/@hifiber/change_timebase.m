function change_timebase(OBJ, NEW_TIMESTAMPS)
%
%
%
%

valid_types = {'dff', 'raw', 'baseline', 'baseline_rem', 'reref', 'reference'};

% interpolate all traces using the new timestamps

for i = 1:length(OBJ)

    switch lower(OBJ(i).options.change_method)

        case 'interp'

            for j = 1:length(OBJ(i).traces)
                trace_types = fieldnames(OBJ(i).traces(j));

                for k = 1:length(trace_types)

                    if any(strcmp(trace_types{k}, valid_types)) & ~isempty(OBJ(i).traces(j).(trace_types{k}))
                        nans = isnan(OBJ(i).timestamps) | isnan(OBJ(i).traces(j).(trace_types{k}));

                        use_ts = OBJ(i).timestamps;
                        use_trace = OBJ(i).traces(j).(trace_types{k});

                        use_ts(nans) = [];
                        use_trace(nans) = [];

                        new_trace = interp1(use_ts, use_trace, NEW_TIMESTAMPS);
                        OBJ(i).traces(j).(trace_types{k}) = new_trace;
                    end

                end

            end

        case 'bin'

            % for the new trace, assume we've been given bin idx, so just average in each bin
            trace_types = fieldnames(OBJ(i).traces);

            for j = 1:length(trace_types)

                if any(contains(valid_types, trace_types{j}))

                    concat = [OBJ(i).traces(:).(trace_types{j})];

                    if isempty(concat)
                        continue;
                    end

                    [nsamples, ntraces] = size(concat);

                    new_traces = nan(numel(NEW_TIMESTAMPS), ntraces);
                    [bins, ~, bin_idx] = unique(NEW_TIMESTAMPS);
                    bins(isnan(bins)) = [];

                    upd = hifiber.proc_timer(length(bins), 'frequency', 1e3);

                    for k = 1:length(bins)
                        nassign = sum(NEW_TIMESTAMPS == bins(k));

                        if sum(OBJ(i).timestamps == bins(k)) > 1
                            tmp = mean(concat(OBJ(i).timestamps == bins(k), :));
                        else
                            tmp = concat(OBJ(i).timestamps == bins(k), :);
                        end

                        if ~isempty(tmp)

                            if nassign > 1
                                new_traces(NEW_TIMESTAMPS == bins(k), :) = repmat(tmp, [nassign 1]);
                            elseif nassign == 1
                                new_traces(NEW_TIMESTAMPS == bins(k), :) = tmp;
                            else
                            end

                        end

                        upd(k);

                    end

                    for k = 1:ntraces
                        OBJ(i).traces(k).(trace_types{j}) = new_traces(:, k);
                    end

                end

            end

    end

    OBJ(i).timestamps = NEW_TIMESTAMPS;
    OBJ(i).metadata.fs = round(1 ./ nanmean(diff(NEW_TIMESTAMPS)));

end

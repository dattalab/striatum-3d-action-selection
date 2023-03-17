function window_imaging(OBJ, FIELD)
%
%
%
%
assert(lower(OBJ.data_type(1)) == 'i', 'Must be imaging data to proceed...')

if nargin < 2
    FIELD = 'behavior';
end

use_syllables = OBJ.options.syllable_cutoff;

if isempty(use_syllables)
    use_syllables = length(unique(OBJ.behavior(1).states));
end

%use_syllables=length(unique(OBJ.behavior(1).states));

imaging_counter = 1;
nanzscore = @(x) (x - nanmean(x)) ./ nanstd(x);
upd = kinect_extract.proc_timer(length(OBJ.imaging));

switch lower(FIELD(1))

    case 'b'

        %behavior

        OBJ.stats.model_starts = struct();

        for i = 1:length(OBJ.imaging)

            if ~OBJ.session(i).has_imaging | isempty(OBJ.behavior(i).labels)
                continue;
            end

            all_data = OBJ.normalize_trace([OBJ.imaging(i).traces(:).raw], OBJ.options.use_deltas);
            [smps, nrois] = size(all_data);

            for j = 1:use_syllables

                matches = OBJ.behavior(i).state_starts{j};
                durs = OBJ.behavior(i).state_durations{j};
                matches_stops = OBJ.behavior(i).state_stops{j};

                if isempty(matches)
                    OBJ.stats.model_starts.imaging(j, imaging_counter).wins = nan(OBJ.options.max_lag * 2 + 1, nrois, 1);
                    continue;
                end

                OBJ.stats.model_starts.imaging(j, imaging_counter).wins = ...
                    single(phanalysis.window_data(all_data, matches, OBJ.options.max_lag));
                OBJ.stats.model_starts.imaging(j, imaging_counter).durations = durs;
                OBJ.stats.model_starts.imaging(j, imaging_counter).prev_label = OBJ.behavior(i).labels(max(matches - 1, 1));
                OBJ.stats.model_starts.imaging(j, imaging_counter).next_label = OBJ.behavior(i).labels(min(matches_stops + 1, length(OBJ.behavior(i).labels)));
                OBJ.stats.model_starts.imaging(j, imaging_counter).session_idx = i;
                OBJ.stats.model_starts.imaging(j, imaging_counter).metadata = OBJ.session(i);

            end

            imaging_counter = imaging_counter + 1;
            upd(i);

        end

    case 'c'

        OBJ.stats.changepoints = struct();

        for i = 1:length(OBJ.imaging)

            if ~OBJ.session(i).has_imaging | isempty(OBJ.projections(i).changepoint_score)
                continue;
            end

            map_time = OBJ.metadata.time_mappers{i};

            if OBJ.options.use_model_changepoints & OBJ.options.use_midpoints
                use_labels = OBJ.behavior(i).labels;
                changepoints = find(abs(diff(use_labels)) > 0);

                if mod(length(changepoints), 2) ~= 0
                    changepoints(end) = [];
                end

                tmp1 = changepoints(1:2:end);
                tmp2 = changepoints(2:2:end);
                changepoints = round(mean([tmp1(:) tmp2(:)], 2));
            elseif OBJ.options.use_model_changepoints
                use_labels = OBJ.behavior(i).labels;
                changepoints = find(abs(diff(use_labels)) > 0);
            else
                [~, changepoints] = findpeaks(phanalysis.nanzscore(map_time(OBJ.projections(i).changepoint_score)), ...
                    'minpeakheight', OBJ.options.changepoint_threshold, 'minpeakdistance', 5);
            end

            if isempty(changepoints)
                continue;
            end

            all_data = OBJ.normalize_trace([OBJ.imaging(i).traces(:).raw]);
            OBJ.stats.changepoints.imaging(imaging_counter).wins = ...
                single(phanalysis.window_data(all_data, changepoints, OBJ.options.max_lag));
            OBJ.stats.changepoints.imaging(imaging_counter).session_idx = i;
            OBJ.stats.changepoints.imaging(imaging_counter).metadata = OBJ.session(i);
            imaging_counter = imaging_counter + 1;

            upd(i);

        end

        %changepoints

end

upd(inf);

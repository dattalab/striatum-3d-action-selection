function window_photometry(OBJ, FIELD)
%
%
%
%

assert(lower(OBJ.data_type(1)) == 'p', 'Must be photometry data to proceed...')

if nargin < 2
    FIELD = 'behavior';
end

gcamp_counter = 1;
rcamp_counter = 1;

use_gcamp = [OBJ.session(:).use_gcamp];
use_rcamp = [OBJ.session(:).use_rcamp];

use_syllables = OBJ.options.syllable_cutoff;

if isempty(use_syllables)
    use_syllables = length(unique(OBJ.behavior(1).states));
end

%use_window='(use_window)';
use_window = 'dff';

switch lower(FIELD(1))

    case 'b'

        %behavior

        fprintf('Windowing around syllables...\n')

        upd = kinect_extract.proc_timer(length(OBJ.photometry));
        OBJ.stats.model_starts = struct();

        for i = 1:length(OBJ.photometry)

            if ~OBJ.session(i).has_photometry | ~(use_gcamp(i) | use_rcamp(i)) | isempty(OBJ.behavior(i).labels)
                continue;
            end

            use_labels = [OBJ.behavior(i).labels; nan];

            if use_gcamp(i)

                norm_gcamp = OBJ.normalize_trace(OBJ.photometry(i).traces(1).(use_window));
                norm_gcamp_auto = OBJ.normalize_trace(OBJ.photometry(i).traces(1).reference);

                norm_gcamp_dt = OBJ.normalize_trace(OBJ.photometry(i).traces(1).(use_window), true);
                norm_gcamp_auto_dt = OBJ.normalize_trace(OBJ.photometry(i).traces(1).reference, true);

                if ~isempty(OBJ.options.deconvolve_gcamp)
                    norm_gcamp_deconv = OBJ.normalize_trace(OBJ.photometry(i).traces(1).(use_window), [], OBJ.options.deconvolve_gcamp);
                end

                for j = 1:use_syllables

                    matches = OBJ.behavior(i).state_starts{j};
                    matches_stops = OBJ.behavior(i).state_stops{j};
                    durs = OBJ.behavior(i).state_durations{j};

                    if isempty(matches)
                        OBJ.stats.model_starts.gcamp(j, gcamp_counter).wins = nan(OBJ.options.max_lag * 2 + 1, 1);
                        continue;
                    end

                    OBJ.stats.model_starts.gcamp(j, gcamp_counter).wins = ...
                        single(phanalysis.window_data(norm_gcamp, matches, OBJ.options.max_lag));
                    OBJ.stats.model_starts.gcamp(j, gcamp_counter).wins_dt = ...
                        single(phanalysis.window_data(norm_gcamp_dt, matches, OBJ.options.max_lag));
                    OBJ.stats.model_starts.gcamp(j, gcamp_counter).wins_auto = ...
                        single(phanalysis.window_data(norm_gcamp_auto, matches, OBJ.options.max_lag));
                    OBJ.stats.model_starts.gcamp(j, gcamp_counter).wins_auto_dt = ...
                        single(phanalysis.window_data(norm_gcamp_auto_dt, matches, OBJ.options.max_lag));
                    OBJ.stats.model_starts.gcamp(j, gcamp_counter).durations = durs;
                    OBJ.stats.model_starts.gcamp(j, gcamp_counter).prev_label = use_labels(matches - 1);
                    OBJ.stats.model_starts.gcamp(j, gcamp_counter).next_label = use_labels(matches_stops + 1);
                    OBJ.stats.model_starts.gcamp(j, gcamp_counter).session_idx = i;

                    if ~isempty(OBJ.options.deconvolve_gcamp)
                        OBJ.stats.model_starts.gcamp(j, gcamp_counter).wins_deconv = ...
                            single(phanalysis.window_data(norm_gcamp_deconv, matches, OBJ.options.max_lag));
                    end

                end

                gcamp_counter = gcamp_counter + 1;

            end

            if use_rcamp(i)

                if length(OBJ.photometry(i).traces) > 4
                    norm_rcamp = OBJ.normalize_trace(OBJ.photometry(i).traces(5).(use_window));
                    norm_rcamp_auto = OBJ.normalize_trace(OBJ.photometry(i).traces(5).reference);
                    norm_rcamp_dt = OBJ.normalize_trace(OBJ.photometry(i).traces(5).(use_window), true);
                    norm_rcamp_auto_dt = OBJ.normalize_trace(OBJ.photometry(i).traces(5).reference, true);
                else
                    norm_rcamp = OBJ.normalize_trace(OBJ.photometry(i).traces(4).(use_window));
                    norm_rcamp_auto = OBJ.normalize_trace(OBJ.photometry(i).traces(4).reference);
                    norm_rcamp_dt = OBJ.normalize_trace(OBJ.photometry(i).traces(4).(use_window), true);
                    norm_rcamp_auto_dt = OBJ.normalize_trace(OBJ.photometry(i).traces(4).reference, true);
                end

                if ~isempty(OBJ.options.deconvolve_rcamp)
                    norm_rcamp_deconv = OBJ.normalize_trace(OBJ.photometry(i).traces(4).(use_window), [], OBJ.options.deconvolve_rcamp);
                end

                for j = 1:use_syllables

                    matches = OBJ.behavior(i).state_starts{j};
                    matches_stops = OBJ.behavior(i).state_stops{j};
                    durs = OBJ.behavior(i).state_durations{j};

                    if isempty(matches)
                        OBJ.stats.model_starts.rcamp(j, rcamp_counter).wins = nan(OBJ.options.max_lag * 2 + 1, 1);
                        continue;
                    end

                    OBJ.stats.model_starts.rcamp(j, rcamp_counter).wins = ...
                        single(phanalysis.window_data(norm_rcamp, matches, OBJ.options.max_lag));
                    OBJ.stats.model_starts.rcamp(j, rcamp_counter).wins_dt = ...
                        single(phanalysis.window_data(norm_rcamp_dt, matches, OBJ.options.max_lag));
                    OBJ.stats.model_starts.rcamp(j, rcamp_counter).wins_auto = ...
                        single(phanalysis.window_data(norm_rcamp_auto, matches, OBJ.options.max_lag));
                    OBJ.stats.model_starts.rcamp(j, rcamp_counter).wins_auto_dt = ...
                        single(phanalysis.window_data(norm_rcamp_auto_dt, matches, OBJ.options.max_lag));
                    OBJ.stats.model_starts.rcamp(j, rcamp_counter).durations = durs;
                    OBJ.stats.model_starts.rcamp(j, rcamp_counter).prev_label = use_labels(matches - 1);
                    OBJ.stats.model_starts.rcamp(j, rcamp_counter).next_label = use_labels(matches_stops + 1);
                    OBJ.stats.model_starts.rcamp(j, rcamp_counter).session_idx = i;

                    if ~isempty(OBJ.options.deconvolve_rcamp)
                        OBJ.stats.model_starts.rcamp(j, rcamp_counter).wins_deconv = ...
                            single(phanalysis.window_data(norm_rcamp_deconv, matches, OBJ.options.max_lag));
                    end

                end

                rcamp_counter = rcamp_counter + 1;

            end

            upd(i);

        end

    case 'c'

        OBJ.stats.changepoints = struct();
        fprintf('Windowing around changepoints...\n');
        upd = kinect_extract.proc_timer(length(OBJ.photometry));

        for i = 1:length(OBJ.photometry)

            if ~OBJ.session(i).has_photometry | ~(use_gcamp(i) | use_rcamp(i)) | ~strcmp(OBJ.session(i).group, 'ctrl')
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
                %use_labels(use_labels>use_syllables)=nan;
                changepoints = find(abs(diff(use_labels)) > 0);
            else
                [~, changepoints] = findpeaks(phanalysis.nanzscore(map_time(OBJ.projections(i).changepoint_score)), ...
                    'minpeakheight', OBJ.options.changepoint_threshold, 'minpeakdistance', 5);
            end

            if isempty(changepoints)
                continue;
            end

            if use_gcamp(i)

                norm_gcamp = OBJ.normalize_trace(OBJ.photometry(i).traces(1).(use_window));
                norm_gcamp_auto = OBJ.normalize_trace(OBJ.photometry(i).traces(1).reference);

                norm_gcamp_dt = OBJ.normalize_trace(OBJ.photometry(i).traces(1).(use_window), true);
                norm_gcamp_auto_dt = OBJ.normalize_trace(OBJ.photometry(i).traces(1).reference, true);

                tidx = [1:length(norm_gcamp_dt) - 1];
                event_tmp = phanalysis.nanzscore(norm_gcamp_dt);
                event_times = event_tmp(tidx) < 1 & event_tmp(tidx + 1) >= 1;
                event_times = single([false; event_times(:)]);

                OBJ.stats.changepoints.gcamp(gcamp_counter).wins = ...
                    single(phanalysis.window_data(norm_gcamp, changepoints, OBJ.options.max_lag));
                OBJ.stats.changepoints.gcamp(gcamp_counter).wins_auto = ...
                    single(phanalysis.window_data(norm_gcamp_auto, changepoints, OBJ.options.max_lag));
                OBJ.stats.changepoints.gcamp(gcamp_counter).wins_dt = ...
                    single(phanalysis.window_data(norm_gcamp_dt, changepoints, OBJ.options.max_lag));
                OBJ.stats.changepoints.gcamp(gcamp_counter).wins_auto_dt = ...
                    single(phanalysis.window_data(norm_gcamp_auto_dt, changepoints, OBJ.options.max_lag));
                OBJ.stats.changepoints.gcamp(gcamp_counter).event_times = ...
                    single(phanalysis.window_data(event_times, changepoints, OBJ.options.max_lag));
                OBJ.stats.changepoints.gcamp(gcamp_counter).session_idx = i;
                OBJ.stats.changepoints.gcamp(gcamp_counter).metadata = OBJ.session(i);

                if ~isempty(OBJ.options.deconvolve_gcamp)
                    norm_gcamp_deconv = OBJ.normalize_trace(OBJ.photometry(i).traces(1).(use_window), [], OBJ.options.deconvolve_gcamp);
                    OBJ.stats.changepoints.gcamp(gcamp_counter).wins_deconv = ...
                        single(phanalysis.window_data(norm_gcamp_deconv, changepoints, OBJ.options.max_lag));
                end

                gcamp_counter = gcamp_counter + 1;

            end

            if use_rcamp(i)

                if length(OBJ.photometry(i).traces) > 4
                    norm_rcamp = OBJ.normalize_trace(OBJ.photometry(i).traces(5).(use_window));
                    norm_rcamp_auto = OBJ.normalize_trace(OBJ.photometry(i).traces(5).reference);
                    norm_rcamp_dt = OBJ.normalize_trace(OBJ.photometry(i).traces(5).(use_window), true);
                    norm_rcamp_auto_dt = OBJ.normalize_trace(OBJ.photometry(i).traces(5).reference, true);
                else
                    norm_rcamp = OBJ.normalize_trace(OBJ.photometry(i).traces(4).(use_window));
                    norm_rcamp_auto = OBJ.normalize_trace(OBJ.photometry(i).traces(4).reference);
                    norm_rcamp_dt = OBJ.normalize_trace(OBJ.photometry(i).traces(4).(use_window), true);
                    norm_rcamp_auto_dt = OBJ.normalize_trace(OBJ.photometry(i).traces(4).reference, true);
                end

                tidx = [1:length(norm_rcamp_dt) - 1];
                event_tmp = phanalysis.nanzscore(norm_rcamp_dt);
                event_times = event_tmp(tidx) < 1 & event_tmp(tidx + 1) >= 1;
                event_times = single([false; event_times(:)]);

                OBJ.stats.changepoints.rcamp(rcamp_counter).wins = ...
                    single(phanalysis.window_data(norm_rcamp, changepoints, OBJ.options.max_lag));
                OBJ.stats.changepoints.rcamp(rcamp_counter).wins_auto = ...
                    single(phanalysis.window_data(norm_rcamp_auto, changepoints, OBJ.options.max_lag));
                OBJ.stats.changepoints.rcamp(rcamp_counter).wins_dt = ...
                    single(phanalysis.window_data(norm_rcamp_dt, changepoints, OBJ.options.max_lag));
                OBJ.stats.changepoints.rcamp(rcamp_counter).wins_auto_dt = ...
                    single(phanalysis.window_data(norm_rcamp_auto_dt, changepoints, OBJ.options.max_lag));
                OBJ.stats.changepoints.rcamp(rcamp_counter).event_times = ...
                    single(phanalysis.window_data(event_times, changepoints, OBJ.options.max_lag));
                OBJ.stats.changepoints.rcamp(rcamp_counter).session_idx = i;
                OBJ.stats.changepoints.rcamp(rcamp_counter).metadata = OBJ.session(i);

                if ~isempty(OBJ.options.deconvolve_rcamp)
                    norm_rcamp_deconv = OBJ.normalize_trace(OBJ.photometry(i).traces(4).(use_window), [], OBJ.options.deconvolve_rcamp);
                    OBJ.stats.changepoints.rcamp(rcamp_counter).wins_deconv = ...
                        single(phanalysis.window_data(norm_rcamp_deconv, changepoints, OBJ.options.max_lag));
                end

                rcamp_counter = rcamp_counter + 1;

            end

            upd(i);

        end

        %changepoints

end

upd(inf);

function SLICED_NEURAL = slice_syllables_neural(OBJ, SYLLABLE_IDX, IDX, SUPPRESS_OUTPUT)
%
%
%
%
%

is_photometry = lower(OBJ.data_type(1)) == 'p';

if nargin < 4 | isempty(SUPPRESS_OUTPUT)
    SUPPRESS_OUTPUT = false;
end

if (nargin < 3 | isempty(IDX)) & is_photometry
    IDX = 1:length(OBJ.photometry);
elseif (nargin < 3 | isempty(IDX))
    IDX = 1:length(OBJ.imaging);
end

if nargin < 2 | isempty(SYLLABLE_IDX)
    SYLLABLE_IDX = 1:OBJ.options.syllable_cutoff;
end

gcamp_counter = 1;
rcamp_counter = 1;
imaging_counter = 1;

if is_photometry
    use_gcamp = [OBJ.session(:).use_gcamp];
    use_rcamp = [OBJ.session(:).use_rcamp];
end

%use_window='(use_window)';
use_window = 'dff';

fprintf('Windowing around syllables...\n')

if ~SUPPRESS_OUTPUT
    upd = kinect_extract.proc_timer(length(IDX));
end

SLICED_NEURAL = struct();

for i = 1:length(IDX)

    if is_photometry

        if ~OBJ.session(IDX(i)).has_photometry | ~(use_gcamp(IDX(i)) | use_rcamp(IDX(i))) | isempty(OBJ.behavior(IDX(i)).labels)
            continue;
        end

    else

        if ~OBJ.session(IDX(i)).has_imaging | isempty(OBJ.behavior(IDX(i)).labels)
            continue;
        end

    end

    use_labels = [OBJ.behavior(IDX(i)).labels; nan];

    if is_photometry & use_gcamp(IDX(i))

        use_obj = OBJ.photometry(IDX(i));
        use_beh = OBJ.behavior(IDX(i));

        norm_gcamp = OBJ.normalize_trace(use_obj.traces(1).(use_window));
        norm_gcamp_auto = OBJ.normalize_trace(use_obj.traces(1).reference);

        norm_gcamp_dt = OBJ.normalize_trace(use_obj.traces(1).(use_window), true);
        norm_gcamp_auto_dt = OBJ.normalize_trace(use_obj.traces(1).reference, true);

        if ~isempty(OBJ.options.deconvolve_gcamp)
            norm_gcamp_deconv = OBJ.normalize_trace(use_obj.traces(1).(use_window), [], OBJ.options.deconvolve_gcamp);
        end

        for j = 1:length(SYLLABLE_IDX)

            matches = use_beh.state_starts{SYLLABLE_IDX(j)};
            matches_stops = use_beh.state_stops{SYLLABLE_IDX(j)};
            durs = use_beh.state_durations{SYLLABLE_IDX(j)};

            if isempty(matches)
                SLICED_NEURAL.gcamp(j, gcamp_counter).wins = nan(OBJ.options.max_lag * 2 + 1, 1);
                continue;
            end

            SLICED_NEURAL.gcamp(j, gcamp_counter).wins = ...
                single(phanalysis.window_data(norm_gcamp, matches, OBJ.options.max_lag));
            SLICED_NEURAL.gcamp(j, gcamp_counter).wins_dt = ...
                single(phanalysis.window_data(norm_gcamp_dt, matches, OBJ.options.max_lag));
            SLICED_NEURAL.gcamp(j, gcamp_counter).wins_auto = ...
                single(phanalysis.window_data(norm_gcamp_auto, matches, OBJ.options.max_lag));
            SLICED_NEURAL.gcamp(j, gcamp_counter).wins_auto_dt = ...
                single(phanalysis.window_data(norm_gcamp_auto_dt, matches, OBJ.options.max_lag));
            SLICED_NEURAL.gcamp(j, gcamp_counter).durations = durs;
            SLICED_NEURAL.gcamp(j, gcamp_counter).prev_label = use_labels(matches - 1);
            SLICED_NEURAL.gcamp(j, gcamp_counter).next_label = use_labels(matches_stops + 1);
            SLICED_NEURAL.gcamp(j, gcamp_counter).session_idx = i;

            if ~isempty(OBJ.options.deconvolve_gcamp)
                SLICED_NEURAL.gcamp(j, gcamp_counter).wins_deconv = ...
                    single(phanalysis.window_data(norm_gcamp_deconv, matches, OBJ.options.max_lag));
            end

        end

        gcamp_counter = gcamp_counter + 1;
        clear use_obj;
        clear use_beh;

    end

    if is_photometry & use_rcamp(i)

        use_obj = OBJ.photometry(IDX(i));
        use_beh = OBJ.behavior(IDX(i));

        if length(use_obj.traces) > 4
            norm_rcamp = OBJ.normalize_trace(use_obj.traces(5).(use_window));
            norm_rcamp_auto = OBJ.normalize_trace(use_obj.traces(5).reference);
            norm_rcamp_dt = OBJ.normalize_trace(use_obj.traces(5).(use_window), true);
            norm_rcamp_auto_dt = OBJ.normalize_trace(use_obj.traces(5).reference, true);
        else
            norm_rcamp = OBJ.normalize_trace(use_obj.traces(4).(use_window));
            norm_rcamp_auto = OBJ.normalize_trace(use_obj.traces(4).reference);
            norm_rcamp_dt = OBJ.normalize_trace(use_obj.traces(4).(use_window), true);
            norm_rcamp_auto_dt = OBJ.normalize_trace(use_obj.traces(4).reference, true);
        end

        if ~isempty(OBJ.options.deconvolve_rcamp)
            norm_rcamp_deconv = OBJ.normalize_trace(use_obj.traces(4).(use_window), [], OBJ.options.deconvolve_rcamp);
        end

        for j = 1:length(SYLLABLE_IDX)

            matches = use_beh.state_starts{SYLLABLE_IDX(j)};
            matches_stops = use_beh.state_stops{SYLLABLE_IDX(j)};
            durs = use_beh.state_durations{SYLLABLE_IDX(j)}; ;

            if isempty(matches)
                SLICED_NEURAL.rcamp(j, rcamp_counter).wins = nan(OBJ.options.max_lag * 2 + 1, 1);
                continue;
            end

            SLICED_NEURAL.rcamp(j, rcamp_counter).wins = ...
                single(phanalysis.window_data(norm_rcamp, matches, OBJ.options.max_lag));
            SLICED_NEURAL.rcamp(j, rcamp_counter).wins_dt = ...
                single(phanalysis.window_data(norm_rcamp_dt, matches, OBJ.options.max_lag));
            SLICED_NEURAL.rcamp(j, rcamp_counter).wins_auto = ...
                single(phanalysis.window_data(norm_rcamp_auto, matches, OBJ.options.max_lag));
            SLICED_NEURAL.rcamp(j, rcamp_counter).wins_auto_dt = ...
                single(phanalysis.window_data(norm_rcamp_auto_dt, matches, OBJ.options.max_lag));
            SLICED_NEURAL.rcamp(j, rcamp_counter).durations = durs;
            SLICED_NEURAL.rcamp(j, rcamp_counter).prev_label = use_labels(matches - 1);
            SLICED_NEURAL.rcamp(j, rcamp_counter).next_label = use_labels(matches_stops + 1);
            SLICED_NEURAL.rcamp(j, rcamp_counter).session_idx = i;

            if ~isempty(OBJ.options.deconvolve_rcamp)
                SLICED_NEURAL.rcamp(j, rcamp_counter).wins_deconv = ...
                    single(phanalysis.window_data(norm_rcamp_deconv, matches, OBJ.options.max_lag));
            end

        end

        rcamp_counter = rcamp_counter + 1;
        clear use_obj;
        clear use_beh;

    end

    if ~is_photometry

        use_beh = OBJ.behavior(IDX(i));

        all_data = OBJ.normalize_trace([OBJ.imaging(IDX(i)).traces(:).raw], OBJ.options.use_deltas);
        [smps, nrois] = size(all_data);

        for j = 1:length(SYLLABLE_IDX)

            matches = use_beh.state_starts{SYLLABLE_IDX(j)};
            matches_stops = use_beh.state_stops{SYLLABLE_IDX(j)};
            durs = use_beh.state_durations{SYLLABLE_IDX(j)};

            if isempty(matches)
                SLICED_NEURAL.imaging(j, imaging_counter).wins = nan(OBJ.options.max_lag * 2 + 1, nrois, 1);
                continue;
            end

            SLICED_NEURAL.imaging(j, imaging_counter).wins = ...
                single(phanalysis.window_data(all_data, matches, OBJ.options.max_lag));
            SLICED_NEURAL.imaging(j, imaging_counter).durations = durs;
            SLICED_NEURAL.imaging(j, imaging_counter).prev_label = OBJ.behavior(i).labels(max(matches - 1, 1));
            SLICED_NEURAL.imaging(j, imaging_counter).next_label = OBJ.behavior(i).labels(min(matches_stops + 1, length(OBJ.behavior(i).labels)));
            SLICED_NEURAL.imaging(j, imaging_counter).session_idx = i;
            SLICED_NEURAL.imaging(j, imaging_counter).metadata = OBJ.session(i);

        end

        imaging_counter = imaging_counter + 1;

    end

    if ~SUPPRESS_OUTPUT
        upd(i);
    end

end

if ~SUPPRESS_OUTPUT
    upd(inf);
end

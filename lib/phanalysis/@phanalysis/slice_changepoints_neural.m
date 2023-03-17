function SLICED_NEURAL = slice_changepoints_neural(OBJ, IDX, SUPPRESS_OUTPUT)
%
%
%
%
%
%

is_photometry = lower(OBJ.data_type(1)) == 'p';

if nargin < 3 | isempty(SUPPRESS_OUTPUT)
    SUPPRESS_OUTPUT = false;
end

if nargin < 2 & is_photometry
    IDX = 1:length(OBJ.photometry);
elseif nargin < 2
    IDX = 1:length(OBJ.imaging);
end

gcamp_counter = 1;
rcamp_counter = 1;
imaging_counter = 1;

if is_photometry
    use_gcamp = [OBJ.session(:).use_gcamp];
    use_rcamp = [OBJ.session(:).use_rcamp];
end

use_window = 'dff';

SLICED_NEURAL = struct();
fprintf('Windowing around changepoints...\n');

if ~SUPPRESS_OUTPUT
    upd = kinect_extract.proc_timer(length(IDX));
end

for i = 1:length(IDX)

    if is_photometry

        if ~OBJ.session(IDX(i)).has_photometry | ~(use_gcamp(IDX(i)) | use_rcamp(IDX(i))) | ~strcmp(OBJ.session(IDX(i)).group, 'ctrl')
            continue;
        end

    else

        if ~OBJ.session(IDX(i)).has_imaging | isempty(OBJ.projections(IDX(i)).changepoint_score)
            continue;
        end

    end

    if OBJ.options.use_model_changepoints & OBJ.options.use_midpoints
        use_labels = OBJ.behavior(IDX(i)).labels;
        changepoints = find(abs(diff(use_labels)) > 0);

        if mod(length(changepoints), 2) ~= 0
            changepoints(end) = [];
        end

        tmp1 = changepoints(1:2:end);
        tmp2 = changepoints(2:2:end);
        changepoints = round(mean([tmp1(:) tmp2(:)], 2));
    elseif OBJ.options.use_model_changepoints
        use_labels = OBJ.behavior(IDX(i)).labels;
        %use_labels(use_labels>use_syllables)=nan;
        changepoints = find(abs(diff(use_labels)) > 0);
    else
        map_time = OBJ.metadata.time_mappers{IDX(i)};
        [~, changepoints] = findpeaks(phanalysis.nanzscore(map_time(OBJ.projections(IDX(i)).changepoint_score)), ...
            'minpeakheight', OBJ.options.changepoint_threshold, 'minpeakdistance', 5);
    end

    if isempty(changepoints)
        continue;
    end

    if is_photometry & use_gcamp(IDX(i))

        use_obj = OBJ.photometry(IDX(i));
        norm_gcamp = OBJ.normalize_trace(use_obj.traces(1).(use_window));
        norm_gcamp_auto = OBJ.normalize_trace(use_obj.traces(1).reference);

        norm_gcamp_dt = OBJ.normalize_trace(use_obj.traces(1).(use_window), true);
        norm_gcamp_auto_dt = OBJ.normalize_trace(use_obj.traces(1).reference, true);

        SLICED_NEURAL.gcamp(gcamp_counter).wins = ...
            single(phanalysis.window_data(norm_gcamp, changepoints, OBJ.options.max_lag));
        SLICED_NEURAL.gcamp(gcamp_counter).wins_auto = ...
            single(phanalysis.window_data(norm_gcamp_auto, changepoints, OBJ.options.max_lag));
        SLICED_NEURAL.gcamp(gcamp_counter).wins_dt = ...
            single(phanalysis.window_data(norm_gcamp_dt, changepoints, OBJ.options.max_lag));
        SLICED_NEURAL.gcamp(gcamp_counter).wins_auto_dt = ...
            single(phanalysis.window_data(norm_gcamp_auto_dt, changepoints, OBJ.options.max_lag));
        SLICED_NEURAL.gcamp(gcamp_counter).session_idx = IDX(i);
        SLICED_NEURAL.gcamp(gcamp_counter).metadata = OBJ.session(IDX(i));

        if ~isempty(OBJ.options.deconvolve_gcamp)
            norm_gcamp_deconv = OBJ.normalize_trace(use_obj.traces(1).(use_window), [], OBJ.options.deconvolve_gcamp);
            norm_gcamp_auto_deconv = OBJ.normalize_trace(use_obj.traces(1).reference, [], OBJ.options.deconvolve_gcamp);
            SLICED_NEURAL.gcamp(gcamp_counter).wins_deconv = ...
                single(phanalysis.window_data(norm_gcamp_deconv, changepoints, OBJ.options.max_lag));
            SLICED_NEURAL.gcamp(gcamp_counter).wins_auto_deconv = ...
                single(phanalysis.window_data(norm_gcamp_auto_deconv, changepoints, OBJ.options.max_lag));
        end

        gcamp_counter = gcamp_counter + 1;
        clear use_obj;

    end

    if is_photometry & use_rcamp(IDX(i))

        use_obj = OBJ.photometry(IDX(i));

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

        SLICED_NEURAL.rcamp(rcamp_counter).wins = ...
            single(phanalysis.window_data(norm_rcamp, changepoints, OBJ.options.max_lag));
        SLICED_NEURAL.rcamp(rcamp_counter).wins_auto = ...
            single(phanalysis.window_data(norm_rcamp_auto, changepoints, OBJ.options.max_lag));
        SLICED_NEURAL.rcamp(rcamp_counter).wins_dt = ...
            single(phanalysis.window_data(norm_rcamp_dt, changepoints, OBJ.options.max_lag));
        SLICED_NEURAL.rcamp(rcamp_counter).wins_auto_dt = ...
            single(phanalysis.window_data(norm_rcamp_auto_dt, changepoints, OBJ.options.max_lag));
        SLICED_NEURAL.rcamp(rcamp_counter).session_idx = IDX(i);
        SLICED_NEURAL.rcamp(rcamp_counter).metadata = OBJ.session(IDX(i));

        if ~isempty(OBJ.options.deconvolve_rcamp)
            norm_rcamp_deconv = OBJ.normalize_trace(use_obj.traces(4).(use_window), [], OBJ.options.deconvolve_rcamp);
            norm_rcamp_auto_deconv = OBJ.normalize_trace(use_obj.traces(4).reference, [], OBJ.options.deconvolve_rcamp);
            SLICED_NEURAL.rcamp(rcamp_counter).wins_deconv = ...
                single(phanalysis.window_data(norm_rcamp_deconv, changepoints, OBJ.options.max_lag));
            SLICED_NEURAL.rcamp(rcamp_counter).wins_auto_deconv = ...
                single(phanalysis.window_data(norm_rcamp_auto_deconv, changepoints, OBJ.options.max_lag));
        end

        rcamp_counter = rcamp_counter + 1;
        clear use_obj;

    end

    if ~is_photometry

        all_data = OBJ.normalize_trace([OBJ.imaging(IDX(i)).traces(:).raw]);
        SLICED_NEURAL.imaging(imaging_counter).wins = ...
            single(phanalysis.window_data(all_data, changepoints, OBJ.options.max_lag));
        SLICED_NEURAL.imaging(imaging_counter).session_idx = IDX(i);
        SLICED_NEURAL.imaging(imaging_counter).metadata = OBJ.session(IDX(i));
        imaging_counter = imaging_counter + 1;

        clear all_data;

    end

    if ~SUPPRESS_OUTPUT
        upd(i);
    end

end

if ~SUPPRESS_OUTPUT
    upd(inf);
end

function compute_scalars_summary(OBJ)
%
%
%

use_scalars = fieldnames(OBJ.projections(1).scalars);
use_syllables = OBJ.options.syllable_cutoff;

OBJ.stats.model_scalars = struct();

fprintf('Getting scalars summary...\n');

upd = kinect_extract.proc_timer(use_syllables);
ispca = isfield(OBJ.projections, 'pca');

for i = 1:use_syllables

    for j = 1:length(OBJ.behavior)

        for k = 1:length(use_scalars)
            OBJ.stats.model_scalars(i, j).(use_scalars{k}) = [];
        end

        if ispca
            OBJ.stats.model_scalars(i, j).pca = [];
        end

        OBJ.stats.model_scalars(i, j).duration = [];

        if isempty(OBJ.behavior(j).labels)
            continue;
        end

        matches = OBJ.behavior(j).state_starts{i};
        durs = OBJ.behavior(j).state_durations{i};

        if isempty(matches)
            continue;
        end

        OBJ.stats.model_scalars(i, j).duration = durs(:)';

        for k = 1:length(use_scalars)

            tmp = OBJ.projections(j).scalars.(use_scalars{k});

            if isempty(tmp)
                continue;
            end

            tmp = OBJ.metadata.time_mappers{j}(tmp);
            use_tmp = single(phanalysis.window_data(tmp, matches, OBJ.options.max_lag_scalars));

            OBJ.stats.model_scalars(i, j).(use_scalars{k}) = use_tmp;

        end

        if ispca

            tmp = OBJ.projections(j).pca;

            if isempty(tmp)
                continue;
            end

            tmp = (OBJ.metadata.time_mappers{j}(tmp));
            use_tmp = single(phanalysis.window_data(tmp, matches, OBJ.options.max_lag_scalars));
            OBJ.stats.model_scalars(i, j).pca = use_tmp;
        end

    end

    upd(i)

end

upd(inf);

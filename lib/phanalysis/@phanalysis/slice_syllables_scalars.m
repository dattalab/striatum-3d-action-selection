function SLICED_SCALARS = slice_syllables_scalars(OBJ, SCALARS, SYLLABLE_IDX, IDX, SUPPRESS_OUTPUT)
%
%

ispca = isfield(OBJ.projections, 'pca');

if nargin < 5 | isempty(SUPPRESS_OUTPUT)
    SUPPRESS_OUTPUT = false;
end

if nargin < 4 | isempty(IDX)
    IDX = 1:length(OBJ.projections);
end

if nargin < 3 | isempty(SYLLABLE_IDX)
    SYLLABLE_IDX = 1:OBJ.options.syllable_cutoff;
end

if nargin < 2 | isempty(SCALARS)
    SCALARS = fieldnames(OBJ.projections(1).scalars);
    get_pca = ispca;
    get_duration = true;
else
    get_pca = strcmpi(SCALARS, 'pca');
    get_duration = strcmpi(SCALARS, 'duration');
    SCALARS(get_pca) = [];
    SCALARS(get_duration) = [];
    get_pca = any(get_pca) & ispca;
    get_duration = any(get_duration);
end

SLICED_SCALARS = struct();

fprintf('Getting scalars summary...\n');

if ~SUPPRESS_OUTPUT
    upd = kinect_extract.proc_timer(length(SYLLABLE_IDX));
end

for i = 1:length(SYLLABLE_IDX)

    for j = 1:length(IDX)

        for k = 1:length(SCALARS)
            SLICED_SCALARS(i, j).(SCALARS{k}) = [];
        end

        if get_pca
            SLICED_SCALARS(i, j).pca = [];
        end

        if get_duration
            SLICED_SCALARS(i, j).duration = [];
        end

        use_beh = OBJ.behavior(IDX(j));

        if isempty(use_beh.labels)
            continue;
        end

        matches = use_beh.state_starts{SYLLABLE_IDX(i)};
        durs = use_beh.state_durations{SYLLABLE_IDX(i)};

        if isempty(matches)
            continue;
        end

        if get_duration
            SLICED_SCALARS(i, j).duration = uint16(durs(:)');
        end

        for k = 1:length(SCALARS)

            tmp = OBJ.projections(IDX(j)).scalars.(SCALARS{k});

            if isempty(tmp)
                continue;
            end

            tmp = OBJ.metadata.time_mappers{IDX(j)}(tmp);
            use_tmp = single(phanalysis.window_data(tmp, matches, OBJ.options.max_lag_scalars));
            SLICED_SCALARS(i, j).(SCALARS{k}) = use_tmp;

        end

        if get_pca

            tmp = OBJ.projections(IDX(j)).pca;

            if isempty(tmp)
                continue;
            end

            tmp = (OBJ.metadata.time_mappers{IDX(j)}(tmp));
            use_tmp = single(phanalysis.window_data(tmp, matches, OBJ.options.max_lag_scalars));
            SLICED_SCALARS(i, j).pca = use_tmp;
        end

    end

    if ~SUPPRESS_OUTPUT
        upd(i)
    end

end

if ~SUPPRESS_OUTPUT
    upd(inf);
end

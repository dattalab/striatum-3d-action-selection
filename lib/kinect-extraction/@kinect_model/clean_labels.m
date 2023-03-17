function BAD_STATES = clean_labels(OBJ, MIN_DURATION, FILL)
%Scans for states < MIN_DURATION and replaces them with the previous state (or nan)
%
%
%
%

if nargin < 3
    FILL = false;
end

if nargin < 2 | isempty(MIN_DURATION)
    MIN_DURATION = 2;
end

all_durs = cat(1, OBJ(:).state_durations);
dur_modes = nan(size(OBJ(1).states));

for i = 1:length(dur_modes)
    tmp = cat(1, all_durs{:, i});
    dur_modes(i) = mode(tmp);
end

BAD_STATES = find(dur_modes < MIN_DURATION);

if FILL

    for i = 1:length(OBJ)

        for j = 1:length(BAD_STATES)

            state_starts = OBJ(i).state_starts{BAD_STATES(j)};
            state_stops = OBJ(i).state_stops{BAD_STATES(j)};
            to_del = state_starts < 2;
            state_starts(to_del) = [];
            state_stops(to_del) = [];

            for k = 1:length(state_starts)
                OBJ(i).labels(state_starts(k):state_stops(k)) = OBJ(i).labels(state_starts(k) - 1);
            end

        end

    end

    OBJ.get_syllable_statistics;
end

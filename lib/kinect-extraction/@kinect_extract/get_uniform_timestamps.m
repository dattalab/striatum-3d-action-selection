function [TIMESTAMPS, ADD_IDX, ADD_VEC, PROJ_IDX] = get_uniform_timestamps(OBJ, DF_CHECK, FS)
%
%
%
%
%

if nargin < 3 | isempty(FS)
    FS = 30;
end

if nargin < 2 | isempty(DF_CHECK)
    DF_CHECK = .0433; % difference this large gets corrected
end

% use camera timestamps

TIMESTAMPS = OBJ.timestamps.depth(:, 1);

ADD_IDX = [];

ts_df = diff(TIMESTAMPS);
insert_idx = find(ts_df > DF_CHECK);

frame_period = 1 / FS;
ts_gap = ts_df(insert_idx);
num_insertions = round((ts_gap - frame_period) / (frame_period));

for i = 1:length(insert_idx)
    sequence_to_insert = (1:num_insertions(i)) * frame_period + TIMESTAMPS(insert_idx(i));
    TIMESTAMPS = [TIMESTAMPS(1:insert_idx(i)); sequence_to_insert(:); TIMESTAMPS(insert_idx(i) + 1:end)];
    ADD_IDX = [ADD_IDX (insert_idx(i) + 1):(insert_idx(i) + num_insertions(i))];
    insert_idx(i + 1:end) = insert_idx(i + 1:end) + num_insertions(i);
end

ADD_VEC = true(size(TIMESTAMPS));
ADD_VEC(ADD_IDX) = false;


OBJ.projections.proj_idx = nan(size(TIMESTAMPS));
OBJ.projections.proj_idx(ADD_VEC) = 1:OBJ.metadata.nframes;

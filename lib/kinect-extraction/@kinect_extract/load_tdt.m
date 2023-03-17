function [DATA, TS, TDT_METADATA] = load_tdt(OBJ, CH, SYNC)
% this requires nidaq timestamps to work, basic logic:
% (1) use pulse train to determine which nidaq sample each tdt sample corresponds to
% (2) how to this?  (a) resample, (b) match sample by sample (e.g. 3rd sample in 1st pulse)
%
% then the rest is straightforward, that is we know which nidaq TS corresponds to which tdt sample

DATA = [];
TS = [];
TDT_METADATA = [];

if nargin < 2
    CH = 8;
end

% todo: in all circuiTS, second to last is sync and last is timestamps (like NI)

if nargin < 3

    if CH == 8
        SYNC = 7;
    elseif CH == 4
        SYNC = 3;
    end

end

% get the first set of data, should be float32

filenames = fieldnames(OBJ.files);
hits = find(~cellfun(@isempty, regexp(filenames, 'tdt_data_[0-9]*')));
nfiles = length(hits);

% exclude files that don't exist yo

filenames = filenames(hits);
use_filenames = cell(1, nfiles);
to_del = [];

for i = 1:nfiles

    if ~OBJ.files.(filenames{i}){2}
        to_del = [to_del i];
        continue;
    end

    use_filenames{i} = OBJ.files.(filenames{i}){1};

end

use_filenames(to_del) = [];
nfiles = length(use_filenames);

if nfiles < 1
    return;
end

DATA = cell(1, nfiles);
TS = cell(1, nfiles);
TDT_METADATA = cell(1, nfiles);

for i = 1:nfiles

    timer_upd = kinect_extract.proc_timer(CH);

    fid = fopen(use_filenames{i}, 'rb');
    first_row = fread(fid, [1 inf], 'float32', (CH - 1) * 4, 'ieee-be');
    frewind(fid);
    DATA{i} = zeros(size(first_row, 2), CH);
    DATA{i}(:, 1) = first_row;

    to_scan = [2:CH];
    is_int = false(1, length(to_scan));

    if CH == 8
        is_int(end - 1:end) = true;
    elseif CH == 4
        is_int(1:2) = true;
    end

    timer_upd(1);

    for j = 1:length(to_scan)
        fseek(fid, (to_scan(j) - 1) * 4, -1);

        if is_int(j)
            DATA{i}(:, to_scan(j)) = fread(fid, [1 inf], 'int32', (CH - 1) * 4, 'ieee-be');
        else
            DATA{i}(:, to_scan(j)) = fread(fid, [1 inf], 'float32', (CH - 1) * 4, 'ieee-be');
        end

        frewind(fid);
        timer_upd(1 + j);

    end

    fclose(fid);

    [path, file, ext] = fileparts(use_filenames{i});
    metadata_filename = fullfile(path, [file '.json']);

    if exist(metadata_filename, 'file')
        TDT_METADATA{i} = loadjson(metadata_filename);
    else
        TDT_METADATA{i} = [];
    end

    OBJ.metadata.tdt{i} = TDT_METADATA{i};
    raw_ts = DATA{i}(:, end);
    DATA{i}(:, end) = [];

    gaps = diff(raw_ts);

    if ~any(gaps > 1)
        fprintf('No gaps found in timestamps, timebase is uniform\n');
    else
        warning('Warning:  %i gaps found in timestamps, timebase is not uniform\n', sum(gaps > 1));
    end

    while any(gaps > 1)

        gaps_idx = find(gaps > 1);

        cur_gap = gaps_idx(1);
        cur_gap_size = gaps(cur_gap);

        insert_ts = [raw_ts(cur_gap) + 1:raw_ts(cur_gap) + (cur_gap_size - 1)]';
        raw_ts = [raw_ts(1:cur_gap); insert_ts; raw_ts(cur_gap + 1:end)];

        insert_data = nan(numel(insert_ts), size(DATA{i}, 2));
        DATA{i} = [DATA{i}(1:cur_gap, :); insert_data; DATA{i}(cur_gap + 1:end, :)];

        gaps = diff(raw_ts);

    end

    TS{i} = diff(raw_ts) .* (1 / OBJ.metadata.tdt{i}.status.sampling_rate);
    TS{i} = cumsum([0; TS{i}(:)]);
    %TS=raw_ts;

end

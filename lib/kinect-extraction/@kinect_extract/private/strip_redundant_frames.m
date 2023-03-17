function kinect_strip_redundant_frames(DATAFILE, MEM_VAR, OUTPUT_FILE)
%
%
%
%

[opts, ~, opts_names] = kinect_get_defaults('common', 'track');
time_buffer = nan(opts.eta_buffer, 1);

frame_memmap = matfile(DATAFILE);
[height, width, nframes] = size(frame_memmap, MEM_VAR);

% get timestamps

timestamps = kinect_read_csv('../depth_ts.txt');
df_ts = diff([-10; timestamps(:, 1)]);
keep_idx = find(df_ts ~= 0);
fprintf('Will copy %i frames\n', length(keep_idx));

frame_copy_memmap = matfile(OUTPUT_FILE);
frame_copy_memmap.Properties.Writable = true;
tmp = whos(frame_memmap, MEM_VAR);
frame_copy_memmap = kinect_matfile_initvar(frame_copy_memmap, tmp.class, MEM_VAR, [height width length(keep_idx)]);

for i = 1:length(keep_idx)

    if i == 1
        [proc_time time_rem rev_string time_buffer] = kinect_proctimer( ...
            i, length(keep_idx), opts.eta_counter, time_buffer);
    else
        [proc_time time_rem rev_string time_buffer] = kinect_proctimer( ...
            i, length(keep_idx), opts.eta_counter, time_buffer, proc_time, time_rem, rev_string);
    end

    frame_copy_memmap.(MEM_VAR)(:, :, i) = frame_memmap.(MEM_VAR)(:, :, keep_idx(i));
end

% copy any flags

fprintf('\n');
tmp = whos('-file', DATAFILE);
copy_flags = strcmp({tmp(:).class}, 'logical');
tmp_vars = {tmp(:).name};
copy_vars = tmp_vars(copy_flags);
frame_copy_memmap.frame_idx = keep_idx;

for i = 1:length(copy_vars)
    fprintf('Copying flag %s\n', copy_vars{i});
    frame_copy_memmap.(copy_vars{i}) = frame_memmap.(copy_vars{i});
end

function write_movies(OBJ)
%
%
%

OBJ.update_status;
task_idx = 1;
p = gcp('nocreate');

if OBJ.status.copy_frames & OBJ.status.remove_background & ...
        OBJ.status.apply_roi & ~OBJ.status.movies_extract & OBJ.files.extract{2}

    fprintf('Writing movie of extracted data\n');
    opts = mergestruct(OBJ.options.common, OBJ.options.extract);
    vid_memmap = matfile(OBJ.files.extract{1});
    [filepath, filename, ~] = fileparts(OBJ.files.extract{1});

    if isempty(p)
        kinect_extract.animate_direct(vid_memmap, ...
            'clim', opts.movie_lims, 'filename', fullfile(filepath, filename), ...
            'mem_var', 'depth_masked', 'cmap', opts.movie_cmap);
    else
        fprintf('Dispatching asynchronous task\n');

        task(task_idx) = parfeval(p, @kinect_extract.animate_direct, 0, ...
            vid_memmap, 'clim', opts.movie_lims, 'filename', fullfile(filepath, filename), ...
            'mem_var', 'depth_masked', 'cmap', opts.movie_cmap);

        task_idx = task_idx + 1;
    end

    clear vid_memmap;

end

% make a movie of the masked data

if OBJ.has_cable

    if OBJ.status.track & ~OBJ.status.movies_track & OBJ.files.track{2}

        fprintf('Writing movie of likelihood surface\n');

        opts = mergestruct(OBJ.options.common, OBJ.options.track);
        vid_memmap = matfile(OBJ.files.track{1});
        [filepath, filename, ~] = fileparts(OBJ.files.track{1});

        if isempty(p)
            kinect_extract.animate_direct(vid_memmap, ...
                'clim', 'auto', 'filename', fullfile(filepath, filename), 'scale', 'log', ...
                'mem_var', 'depth_nocable_em_raw', 'auto_lims', opts.movie_lims, 'auto_per', opts.auto_per, 'cmap', opts.movie_cmap);
        else
            fprintf('Dispatching asynchronous task\n');
            task(task_idx) = parfeval(p, @kinect_extract.animate_direct, 0, vid_memmap, ...
                'clim', 'auto', 'filename', fullfile(filepath, filename), 'scale', 'log', ...
                'mem_var', 'depth_nocable_em_raw', 'auto_lims', opts.movie_lims, 'auto_per', opts.auto_per, 'cmap', opts.movie_cmap);
            task_idx = task_idx + 1;
        end

        clear vid_memmap;
    end

end

if OBJ.status.track_stats & ~OBJ.status.movies_track_stats & OBJ.files.track_stats{2} & OBJ.files.extract{2}

    fprintf('Writing movie for tracking stats\n');

    load(OBJ.files.track_stats{1}, 'depth_stats_fixed');
    opts = mergestruct(OBJ.options.common, OBJ.options.stats);
    vid_memmap = matfile(OBJ.files.extract{1});
    [filepath, filename, ~] = fileparts(OBJ.files.track_stats{1});

    % write out a video

    if isempty(p)
        kinect_extract.animate_direct(vid_memmap, ...
            'clim', opts.movie_lims, 'filename', fullfile(filepath, filename), ...
            'stats', depth_stats_fixed, 'mem_var', 'depth_masked', ...
            'weighted_centroid', opts.weighted_centroid, 'cmap', opts.movie_cmap);
    else
        fprintf('Dispatching asynchronous task\n');
        task(task_idx) = parfeval(p, @kinect_extract.animate_direct, 0, vid_memmap, ...
            'clim', opts.movie_lims, 'filename', fullfile(filepath, filename), ...
            'stats', depth_stats_fixed, 'mem_var', 'depth_masked', ...
            'weighted_centroid', opts.weighted_centroid, 'cmap', opts.movie_cmap);
        task_idx = task_idx + 1;
    end

    clear vid_memmap;

end

if OBJ.status.bound & ~OBJ.status.movies_bound & OBJ.files.bound{2}

    % make a movie of the masked data
    fprintf('Writing movie of bounded mouse\n');

    opts = mergestruct(OBJ.options.common, OBJ.options.bound);
    [filepath, filename, ~] = fileparts(OBJ.files.bound{1});
    vid_memmap = matfile(OBJ.files.bound{1});

    if isempty(p)
        kinect_extract.animate_direct(vid_memmap, ...
            'clim', opts.movie_lims, 'filename', fullfile(filepath, filename), ...
            'mem_var', 'depth_bounded', 'cmap', opts.movie_cmap);
    else
        fprintf('Dispatching asynchronous task...\n');
        task(task_idx) = parfeval(p, @kinect_extract.animate_direct, 0, vid_memmap, ...
            'clim', opts.movie_lims, 'filename', fullfile(filepath, filename), ...
            'mem_var', 'depth_bounded', 'cmap', opts.movie_cmap);
        task_idx = task_idx + 1;
    end

    clear vid_memmap;

end

if OBJ.status.orient & ~OBJ.status.movies_orient & OBJ.files.orient{2}

    fprintf('Writing a video of the bounded, centered mouse...\n');

    % make a movie of the masked data
    opts = mergestruct(OBJ.options.common, OBJ.options.orient);
    [filepath, filename, ~] = fileparts(OBJ.files.orient{1});
    vid_memmap = matfile(OBJ.files.orient{1});

    if isempty(p)
        kinect_extract.animate_direct(vid_memmap, ...
            'clim', opts.movie_lims, 'filename', fullfile(filepath, filename), ...
            'mem_var', 'depth_bounded_rotated', 'cmap', opts.movie_cmap);
    else
        fprintf('Dispatching asynchronous task\n');
        task(task_idx) = parfeval(p, @kinect_extract.animate_direct, 0, vid_memmap, ...
            'clim', opts.movie_lims, 'filename', fullfile(filepath, filename), ...
            'mem_var', 'depth_bounded_rotated', 'cmap', opts.movie_cmap);
        task_idx = task_idx + 1;
    end

    clear vid_memmap;
end

if task_idx == 1
    task = [];
else
    fprintf('Waiting for movie writing to finish...\n');
    wait(task);
    fprintf('All movies complete...\n');
end

OBJ.update_status;

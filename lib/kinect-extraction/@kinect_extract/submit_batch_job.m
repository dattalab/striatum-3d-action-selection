function submit_batch_job(OBJ, PROFILE)
% We can do this locally, or submit to cluster (for now just configured for Orchestra)
%
%
%

% only work on objects that aren't finished

[done_preprocessing, movies_done] = OBJ.done_preprocessing;

switch lower(PROFILE(1))

    case 'l'

        % local
        for i = find((~done_preprocessing | ~movies_done) & ~OBJ.to_skip)

            bookmark_file = fullfile(OBJ(i).working_dir, OBJ(i).options.common.bookmark);

            if exist(bookmark_file, 'file') == 2
                fprintf('Detected bookmark, skipping directory %s\n', OBJ(i).working_dir);
                continue;
            end

            fprintf('Making bookmark %s\n', bookmark_file);
            fclose(fopen(bookmark_file, 'w'));
            OBJ(i).preprocess;

        end

    case 'o'

        for i = find((~done_preprocessing | ~movies_done) & ~OBJ.to_skip)

            % Orchestra

            opts = OBJ(i).options.batch;
            bookmark_file = fullfile(OBJ(i).working_dir, OBJ(i).options.common.bookmark);

            if exist(bookmark_file, 'file') == 2
                fprintf('Detected bookmark, skipping directory %s\n', OBJ(i).working_dir);
                continue;
            end

            wall_time = sprintf('%i:00', opts.orchestra_wall_time);
            mem_usage = sprintf('%i', opts.orchestra_mem_usage);
            fprintf('Setting up cluster with wall time %s, queue %s, mem usage %s\n', ...
                wall_time, opts.orchestra_queue, mem_usage)
            fprintf('Submitting directory %s for batch processing\n', OBJ(i).working_dir);
            fprintf('Making bookmark %s\n', bookmark_file);
            fclose(fopen(bookmark_file, 'w'));

            ClusterInfo.setWallTime(wall_time);
            ClusterInfo.setQueueName(opts.orchestra_queue);
            ClusterInfo.setMemUsage(mem_usage);
            ClusterInfo.setUserDefinedOptions('-N');
            clust = parcluster;

            batch(clust, @(x) preprocess(x, opts.orchestra_workers + 1), 0, {OBJ(i)}, 'pool', opts.orchestra_workers, ...
                'AutoAttachFiles', false);

        end

    case 'a'

        % EC2/k8s, figure it out...

    otherwise

        error('Did not understand batch profile (l)ocal,(o)rchestra,(a)mazon or (g)ce');

end

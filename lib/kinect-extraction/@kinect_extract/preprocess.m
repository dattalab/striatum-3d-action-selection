function preprocess(OBJ, NTHREADS)
% automatically runs all preprocessing steps
% TODO: make sure this intelligently deals w/ running on Orchestra

if nargin < 2
    NTHREADS = [];
end

if ~isempty(NTHREADS)
    fprintf('Setting number of threads to %i\n', NTHREADS);
    nthreads = maxNumCompThreads(NTHREADS);
    fprintf('Current number of threads:  %i\n', nthreads);
end

for i = 1:length(OBJ)

    % work backwards, if we don't have anything from the END to this point

    [next_step, next_idx, steps] = OBJ(i).get_next_step;

    if ~isnan(next_idx)

        to_complete = steps(next_idx:end);

        % only correct flips if we have a flip detector

        if (lower(OBJ(i).options.flip.method(1)) == 'm' & ~OBJ(i).status.flip_model) | ...
                (lower(OBJ(i).options.flip.method(1)) == 'f' & ~OBJ(i).files.flip{2})
            to_complete(strcmp(to_complete, 'correct_flips')) = [];
        end

        for j = 1:length(to_complete)
            OBJ(i).(to_complete{j});
        end

        bookmark_file = fullfile(OBJ(i).working_dir, OBJ(i).options.common.bookmark);

        if exist(bookmark_file, 'file')
            fprintf('Removing bookmark %s\n', bookmark_file);
            delete(bookmark_file);
        end

        % TODO: smart detection of linux, convert avi using ffmpeg if we have it

    end

end

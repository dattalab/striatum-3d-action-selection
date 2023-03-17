function STATS = average_windows(OBJ, MODEL_STARTS, varargin)
%
%
%
%

STATS = struct();

opts = struct( ...
    'group', '', ...
    'normalize', false, ...
    'time_warp', false, ...
    'warp_dur', 20, ...
    'warp_shift', [- .2 .2], ...
    'randomize_indicators', false, ...
    'chk_fields', '', ...
    'suppress_output', false);

opts_names = fieldnames(opts);
nparams = length(varargin);

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

for i = 1:2:nparams

    if any(strcmp(varargin{i}, opts_names))
        opts.(varargin{i}) = varargin{i + 1};
    end

end

warp_shift_smps = round(OBJ.options.fs * opts.warp_shift);
warp_shift_vec = warp_shift_smps(1):warp_shift_smps(2);

% we can linearly time warp, use the mode, or take all comers

switch lower(OBJ.options.average_time(1))

    case 'w'

        % warping (linear for now)

    case 'p'

        % some percentile chunk

        if strcmp(lower(OBJ.data_type(1)), 'p')
            to_chk = {'gcamp', 'rcamp'};
            ndims = 1;
            nsyllables = max(size(MODEL_STARTS.gcamp, 1), size(MODEL_STARTS.rcamp, 1));
        elseif strcmp(lower(OBJ.data_type(1)), 'i')
            to_chk = {'imaging'};
            ndims = 2;
            nsyllables = size(MODEL_STARTS.imaging, 1);
        end

        if ~opts.suppress_output
            fprintf('Averaging windows...\n')
        end

        center = OBJ.options.max_lag;

        for i = 1:length(to_chk)

            if ~opts.suppress_output
                upd = kinect_extract.proc_timer(nsyllables);
            end

            tmp = MODEL_STARTS.(to_chk{i});

            if ~isempty(opts.chk_fields)
                fields = opts.chk_fields;
            else
                fields = fieldnames(tmp);
                fields(~contains(fields, 'wins')) = [];
            end

            session_idx = [tmp(1, :).session_idx];

            if isfield(OBJ.session, 'group')
                groups = {OBJ.session(session_idx).group};
            else
                groups = '';
            end

            if isempty(opts.group) | isempty(groups)
                use_group = true(size(groups));
            elseif ~isempty(groups)
                use_group = strcmp(groups, opts.group);
            end

            STATS.(sprintf('%s_mu', to_chk{i})) = struct();

            session_rois = cellfun(@(x) size(x, 2), {tmp(1, :).(fields{1})});
            session_idx = cell(size(session_rois));

            for k = 1:length(session_rois)
                session_idx{k} = ones(1, session_rois(k)) * k;
            end

            STATS.(sprintf('%s_mu', to_chk{i})).session_idx = cat(2, session_idx{:});

            for k = 1:nsyllables

                cat_durs = cat(1, tmp(k, use_group).durations);
                use_idx = true(size(cat_durs));

                if ~isempty(OBJ.options.average_percentiles)
                    bounds = prctile(cat_durs, OBJ.options.average_percentiles);
                    use_idx = cat_durs > bounds(1) & cat_durs < bounds(2);
                end

                % TODO: fold in randomizations...

                for l = 1:length(fields)

                    use_mu = sprintf('mu%s', regexprep(fields{l}, 'wins', ''));
                    use_mu_rnd = sprintf('mu_rnd%s', regexprep(fields{l}, 'wins', ''));

                    if ndims == 1

                        cat_fluo = cat(2, tmp(k, use_group).(fields{l}));

                        if opts.randomize_indicators & isempty(opts.group)
                            other_field = setdiff(to_chk, to_chk(i));
                            tmp2 = MODEL_STARTS.(other_field{1});
                            cat_fluo2 = cat(2, tmp2(k, :).(fields{l}));

                            ntrials1 = size(cat_fluo, 2);
                            ntrials2 = size(cat_fluo2, 2);

                            nall = min(ntrials1, ntrials2);

                            big_pool = [cat_fluo(:, 1:nall) cat_fluo2(:, 1:nall)];
                            rnd_pool = randperm(size(big_pool, 2));

                            cat_fluo = big_pool(:, rnd_pool(1:ntrials1));

                        elseif opts.randomize_indicators
                            error('Cannot currently use groups for randomization')
                        end

                        if opts.normalize
                            cat_fluo = phanalysis.nanzscore(cat_fluo);
                        end

                        cat_fluo = cat_fluo(:, use_idx);
                        use_durs = cat_durs(use_idx);

                        if opts.time_warp
                            warp_fluo = nan(opts.warp_dur, size(cat_fluo, 2));
                            uniq_durs = unique(use_durs);
                            uniq_durs(uniq_durs < 3) = [];

                            for m = 1:length(uniq_durs)
                                idx = use_durs == uniq_durs(m);
                                x = linspace(1, opts.warp_dur, uniq_durs(m) + length(warp_shift_vec));
                                xx = 1:opts.warp_dur;
                                warp_fluo(:, idx) = interp1(x, cat_fluo(center + warp_shift_smps(1) ...
                                    :center + uniq_durs(m) + warp_shift_smps(2), idx), xx);
                            end

                            cat_fluo = warp_fluo;
                            clear warp_fluo;
                        end

                        if ~isempty(cat_fluo)
                            STATS.(sprintf('%s_mu', to_chk{i})).(use_mu)(:, k) = nanmean(cat_fluo, 2);
                        else
                            STATS.(sprintf('%s_mu', to_chk{i})).(use_mu)(:, k) = nan;
                            STATS.(sprintf('%s_mu', to_chk{i})).(use_mu_rnd)(:, :, k) = nan;
                        end

                    elseif ndims == 2

                        tmp_ca = cellfun(@(x) nanmean((x), 3), {tmp(k, :).(fields{l})}, 'UniformOutput', false);
                        STATS.(sprintf('%s_mu', to_chk{i})).(use_mu)(:, :, k) = cat(2, tmp_ca{:});

                    end

                end

                if ~opts.suppress_output
                    upd(k)
                end

            end

            upd(inf);

        end

    otherwise

end

end

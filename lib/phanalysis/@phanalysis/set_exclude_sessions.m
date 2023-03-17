function set_exclude_sessions(OBJ)
%
%
%

mouse_ids = {OBJ.session(:).mouse_id};
mouse_meta_ids = {OBJ.metadata.mouse(:).Name};

if isfield(OBJ.metadata, 'exclude')
    exclude_name = {OBJ.metadata.exclude(:).Name};
    exclude_dates = datenum({OBJ.metadata.exclude(:).Date}, 'mm/dd/yyyy');
else
    exclude_name = {};
    exclude_dates = {};
end

for i = 1:length(OBJ.session)

    % get days since injection

    use_meta = strcmp(mouse_ids{i}, mouse_meta_ids);
    cur_date = OBJ.session(i).datenum;
    inj_date = datenum(OBJ.metadata.mouse(use_meta).InjectionDate);

    excl_mouse = strcmp(lower(OBJ.metadata.mouse(use_meta).Exclude), 'yes');
    has_model = ~isempty(OBJ.behavior(i).labels);

    since_inj = cur_date - inj_date;
    is_first = (cur_date - datenum('03/31/2017', 'mm/dd/yyyy')) == 0;
    is_empty = length(OBJ.photometry(i).traces) < 4;

    if ~is_empty
        is_empty = ~isfield(OBJ.photometry(i).traces(1), 'reference');
    end

    is_sensor = strcmp(lower(OBJ.metadata.mouse(use_meta).RedSensor), ...
        OBJ.options.use_sensor);

    if ~isempty(exclude_name)
        exc_id = strcmp(OBJ.session(i).mouse_id, exclude_name);
        exc_date = abs(bsxfun(@minus, exclude_dates, cur_date)) < 1;
        cur_exc = any(exc_id(:) & exc_date(:));
    else
        cur_exc = false;
    end

    gcamp_cut = false;
    rcamp_cut = false;

    if ~is_empty
        gcamp_cut = prctile(OBJ.photometry(i).traces(1).dff * 1e2, 97.5) > OBJ.options.gcamp_dff_cutoff;

        if length(OBJ.photometry(i).traces) > 4
            rcamp_cut = prctile(OBJ.photometry(i).traces(5).dff * 1e2, 97.5) > OBJ.options.rcamp_dff_cutoff;
        else
            rcamp_cut = prctile(OBJ.photometry(i).traces(4).dff * 1e2, 97.5) > OBJ.options.rcamp_dff_cutoff;
        end

    end

    if isfield(OBJ.photometry(i).metadata, 'ica') & OBJ.options.ica_weights_min > 0

        w = OBJ.photometry(i).metadata.ica.w;
        idx = false(1, size(w, 1));
        idx(OBJ.photometry(i).metadata.ica.ref_idx) = true;

        weights = abs(w(:, idx)) ./ sum(abs(w(:, ~idx)), 2);

        if max(weights) < OBJ.options.ica_weights_min
            gcamp_cut = false;
            rcamp_cut = false;
        end

    end

    OBJ.session(i).use_gcamp = (since_inj >= OBJ.options.gcamp_time_cutoff) & ~is_first & ~is_empty & ~cur_exc & gcamp_cut & ~excl_mouse;
    OBJ.session(i).use_rcamp = (since_inj >= OBJ.options.rcamp_time_cutoff) & ~is_first & ~is_empty & ~cur_exc & rcamp_cut & is_sensor & ~excl_mouse;
    OBJ.session(i).has_model = has_model;
end

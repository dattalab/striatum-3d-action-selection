function MODEL_OBJ = load_model_labels(OBJ, STATE_LABELS, METADATA, IDX)
%
%
%
%
%

if nargin < 4
    IDX = 1;
end

if nargin < 3
    error('Need metadata to continue!');
end

if ~iscell(STATE_LABELS)
    error('State labels must be passed as a cell array');
end

STATE_LABELS = STATE_LABELS(IDX, :);

use_frames = sum(cellfun(@length, STATE_LABELS));
date_loaded = datestr(now);
last_idx = [];

uuids = METADATA.uuids;
phan_uuids = {OBJ.session(:).uuid};

if ischar(uuids) & ~iscell(uuids)
    uuids = cellstr(uuids);
end

if iscell(METADATA.parameters)
    keys = fieldnames(METADATA.parameters{IDX});
else
    keys = fieldnames(METADATA.parameters);
end

OBJ.behavior = kinect_model.empty(length(OBJ.session), 0);
MODEL_OBJ = OBJ.behavior;

for i = length(OBJ.session):-1:1

    if ~isempty(uuids)
        use_idx = strcmp(uuids, phan_uuids{i});

        if ~any(use_idx)
            warning('Found no match for object %i\n', i);
            continue;
        end

    else
        warning('Loading without uuids, no guarantees that incides will match correctly\n');
        use_idx = i;
    end

    use_labels = STATE_LABELS{use_idx};

    if ~isvector(use_labels)
        use_labels = use_labels(end, :);
    end

    %use_labels=OBJ.metadata.time_mappers{i}(use_labels);
    use_labels = use_labels(~isnan(OBJ.projections(i).proj_idx));
    nframes = sum(~isnan(OBJ.projections(i).proj_idx));

    if numel(use_labels) ~= nframes
        fprintf('Frame number from model does not match object frame number\n');
        continue;
    end

    tmp_params = struct();

    if ~iscell(METADATA.parameters)

        for j = 1:length(keys)

            if iscell(METADATA.parameters.(keys{j}))
                tmp_params.(keys{j}) = METADATA.parameters.(keys{j}){IDX};
            else
                tmp_params.(keys{j}) = METADATA.parameters.(keys{j})(IDX);
            end

        end

    else
        tmp_params = METADATA.parameters{IDX};
    end

    OBJ.behavior(i) = kinect_model(use_labels, tmp_params, METADATA.export_uuid);
    MODEL_OBJ(i) = OBJ.behavior(i);
    OBJ.behavior(i).metadata.nframes = use_frames;
    OBJ.behavior(i).metadata.date_loaded = date_loaded;
    OBJ.behavior(i).metadata.model_idx = IDX;
    last_idx = i;
    last_model = MODEL_OBJ(i);

end

MODEL_OBJ.get_syllable_statistics;

if ~isempty(last_idx) & exist(OBJ.options.save_dir, 'dir')

    try
        savejson('', last_model.metadata, ...
            fullfile(OBJ.options.save_dir, sprintf('model-%s-%05i.json', last_model.metadata.uuid, IDX)));
    catch
        warning('Could not save model json file, check to see if %s exists', OBJ(last_idx).options.common.analysis_dir);
    end

end

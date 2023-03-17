function H = group_violin(DATA, varargin)
%
%
%
%
%

opts = struct( ...
    'colors', 'parula', ...
    'groups', [], ...
    'conditions', [], ...
    'intergroup_spacing', 2, ...
    'withingroup_spacing', .75, ...
    'labels', '');

opts_names = fieldnames(opts);
nparams = length(varargin);

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

use_params = [];

for i = 1:2:nparams

    if any(strcmp(varargin{i}, opts_names))
        opts.(varargin{i}) = varargin{i + 1};
        use_params = [use_params i i + 1];
    end

end

varargin(use_params) = [];

if isstruct(DATA)

    fields = fieldnames(DATA);

    if isstruct(DATA.(fields{1}))

        % if it's a struct of structs, assume we have groups then conditions
        tmp = {};
        labels = {};
        opts.conditions = [];
        opts.groups = [];

        for i = 1:length(fields)
            fields2 = fieldnames(DATA.(fields{i}));

            for j = 1:length(fields2)
                tmp{end + 1} = DATA.(fields{i}).(fields2{j});
                opts.conditions(end + 1) = j;
                opts.groups(end + 1) = i;
            end

            labels{i} = regexprep(fields{i}, '_', '');
        end

        DATA = tmp;

    else

        tmp = cell(size(fields));

        for i = 1:length(fields)
            tmp{i} = DATA.(fields{i});
        end

        opts.groups = ones(size(fields));
        opts.conditions = 1:length(fields);
        DATA = tmp;

    end

elseif iscell(DATA) & isempty(opts.groups) & isempty(opts.conditions)

    opts.groups = ones(size(DATA));
    opts.conditions = 1:length(DATA);

elseif iscell(DATA) & isempty(opts.conditions)

    opts.groups = ones(size(DATA));

elseif iscell(DATA)
else
    error('Could not parse input, pass as a struct or cell array')
end

cur_pos = 0;

if ischar(opts.colors)
    colors = colormap(sprintf('%s(%i)', opts.colors, length(unique(opts.conditions))));
elseif isnumeric(opts.colors) & size(opts.colors, 2) == 3
    colors = opts.colors;
else
    error('Colors must either be the name of a colormap or an nx3 matrix of RGB values');
end

xpos = nan(size(DATA));

for i = 1:length(DATA)

    if i > 1

        if (opts.groups(i) - opts.groups(i - 1)) > 0
            cur_pos = cur_pos + opts.intergroup_spacing;
        else
            cur_pos = cur_pos + opts.withingroup_spacing;
        end

    end

    xpos(i) = cur_pos;
    H(i) = Violin(DATA{i}, cur_pos, 'ViolinColor', colors(opts.conditions(i), :), varargin{:});

end

grps = unique(opts.groups);

if length(grps) > 1 & length(labels) == length(grps)
    xticks = [];

    for i = 1:length(labels)
        xticks(end + 1) = mean(xpos(opts.groups == grps(i)));
    end

    set(gca, 'XTick', xticks, 'XTickLabel', labels);
end

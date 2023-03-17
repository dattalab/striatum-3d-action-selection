function [BOX_HANDLE, MED_HANDLE, WHISK_HANDLE] = boxplot(DATA, GRPS, varargin)
%
%
%
%

if nargin < 2, GRPS = []; end

color = 'r';
linewidth = 1;
outliers = 0;
adjacent = 0;
fill_box = 1;
med_color = [0 0 0];
box_color = 'parula';
med_width = 1;
bunching = [];
bunching_offset = 2;
feature_idx = [];
box_width = .8;
linewidth = .5
whiskers = 0;
prctiles = [25 75];

nparams = length(varargin);

if mod(nparams, 2) > 0
    error('Parameters must be specified as parameter/value pairs!');
end

for i = 1:2:nparams

    switch lower(varargin{i})
        case 'color'
            color = varargin{i + 1};
        case 'linewidth'
            linewidth = varargin{i + 1};
        case 'outliers'
            outliers = varargin{i + 1};
        case 'adjacent'
            adjacent = varargin{i + 1};
        case 'fill_box'
            fill_box = varargin{i + 1};
        case 'feature_idx'
            feature_idx = varargin{i + 1};
        case 'bunching'
            bunching = varargin{i + 1};
        case 'bunching_offset'
            bunching_offset = varargin{i + 1};
        case 'box_width'
            box_width = varargin{i + 1};
        case 'box_color'
            box_color = varargin{i + 1};
        case 'med_color'
            med_color = varargin{i + 1};
        case 'whiskers'
            whiskers = varargin{i + 1};
        case 'prctiles'
            prctiles = varargin{i + 1};
    end

end

if isempty(GRPS) & ~iscell(DATA)
    GRPS = ones(size(DATA));
end

% number of styles corresponds to number of grps

if iscell(DATA)

    tmp = [];
    GRPS = [];

    for i = 1:length(DATA)
        tmp2 = DATA{i}(:);
        tmp = [tmp; tmp2];
        GRPS = [GRPS; ones(size(tmp2)) * i];
    end

    clear DATA;
    DATA = tmp;
elseif isempty(GRPS)
    GRPS = ones(size(DATA, 2));
end

uniq_grps = unique(GRPS);
ngrps = length(uniq_grps);

if isempty(feature_idx)
    feature_idx = ones(1, ngrps);
end

uniq_features = unique(feature_idx);
nfeatures = length(uniq_features);

if nfeatures > 1 & (ischar(med_color) | ischar(box_color))
    error('Need to specify multiple colors using n x 3 matrix');
end

% define a polygon to plot as a patch

% TODO: prettify colors, custom spacing, etc.

% use positions property, compact style, etc.

pos_idx = ones(1, ngrps);

if ~isempty(bunching)
    pos_idx(1:bunching:length(pos_idx)) = bunching_offset;
end

pos_idx = cumsum([pos_idx]);
boxplot(DATA, GRPS, 'positions', pos_idx, 'width', box_width, 'boxstyle', 'outline');
grpids = unique(GRPS);
hold on;

WHISK_HANDLE = findobj(gcf, '-regexp', 'Tag', '\w*Whisker');
BOX_HANDLE = findobj(gca, 'tag', 'Box');
MED_HANDLE = findobj(gca, 'tag', 'Median');
set(WHISK_HANDLE, 'LineStyle', '-');

xidx = nan(1, length(BOX_HANDLE));

for i = 1:length(BOX_HANDLE)
    xidx(i) = median(get(BOX_HANDLE(i), 'xdata'));
end

[~, sorting] = sort(xidx);

if fill_box

    for i = 1:nfeatures
        idx = find(feature_idx == uniq_features(i));
        box_color = parula(length(idx));

        for j = 1:length(idx)
            % handles are returned in reverse order

            new_ydata = prctile(DATA(GRPS == grpids(sorting(idx(j)))), prctiles)
            new_ypoints = [new_ydata(1) new_ydata(2) new_ydata(2) new_ydata(1) new_ydata(1)]
            %new_ypoints=get(BOX_HANDLE(idx(j)),'YData')

            if ischar(box_color)
                patch(get(BOX_HANDLE(idx(j)), 'XData'), new_ypoints, ones(1, 3), 'edgecolor', 'k', 'linewidth', linewidth, 'facecolor', box_color);
            else
                patch(get(BOX_HANDLE(idx(j)), 'XData'), new_ypoints, box_color(j, :), 'edgecolor', 'k', 'linewidth', linewidth);
            end

            plot(get(MED_HANDLE(idx(j)), 'XData'), get(MED_HANDLE(idx(j)), 'YData'), 'k-', 'color', med_color, 'linewidth', med_width);

        end

    end

end

if ~whiskers
    delete(WHISK_HANDLE);
end

if ~adjacent
    h = findobj(gcf, '-regexp', 'Tag', '\w*Adjacent');
    delete(h);
end

if ~outliers
    h = findobj(gca, 'tag', 'Outliers');
    delete(h);
end

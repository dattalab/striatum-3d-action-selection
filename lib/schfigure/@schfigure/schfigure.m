classdef schfigure < handle & matlab.mixin.SetGet
properties
    name
    dims
    formats
    renderer
    units
    working_dir
    resolution
    schfigdir
end

properties (SetAccess = private)
    fig
end

properties (Access = private)

end

methods

    function obj = schfigure(FIG, BLACKBG)

        if nargin < 2
            BLACKBG = false;
        end

        if nargin < 1
            FIG = [];
        end

        % read in the defaults

        if ~isa(FIG, 'matlab.ui.Figure')
            FIG = figure('visible', 'off', 'paperpositionmode', 'auto', ...
                'inverthardcopy', 'off');
        end

        obj.fig = FIG;
        obj.use_defaults;

        % only setting schfigdir here, and not while loading schfigname
        if exist(fullfile(pwd(), '.schfigrectory'), 'file')
            obj.schfigdir = pwd();
            fid = fopen(fullfile(pwd(), '.schfigrectory'));
            tmp = fscanf(fid, '%c');
            fclose(fid);
            obj.working_dir = tmp;
            fprintf('Loading schfigurectory: %s\n', obj.working_dir)
        elseif exist('~/.schfigrectory', 'file')
            obj.schfigdir = '~';
            fid = fopen('~/.schfigrectory');
            tmp = fscanf(fid, '%c');
            fclose(fid);
            obj.working_dir = tmp;
            fprintf('Loading schfigurectory: %s\n', obj.working_dir)
        end

        if exist(fullfile(pwd(), '.schfigname'), 'file')
            fid = fopen(fullfile(pwd(), '.schfigname'));
            tmp = fscanf(fid, '%s');
            fclose(fid);
            obj.name = tmp;
            fprintf('Loading schfigname: %s\n', obj.name)
        elseif exist('~/.schfigname', 'file')
            fid = fopen('~/.schfigname');
            tmp = fscanf(fid, '%s');
            fclose(fid);
            obj.name = tmp;
            fprintf('Loading schfigname: %s\n', obj.name)
        end

        % embed our object in the fig handle, reconstitute when we load a matlab Figure
        obj.fig.UserData = obj;
        obj.fig.Visible = 'on';

        if BLACKBG
            whitebg(obj.fig, [0 0 0]);
            obj.fig.Color = [0 0 0];
            obj.fig.InvertHardcopy = 'off';
        else
            obj.fig.Color = [1 1 1];
        end

    end

    function obj = set.name(obj, val)

        if isa(val, 'char')
            obj.name = val;
        elseif isnumeric(val)
            obj.name = num2str(val);
        end

        fid = fopen(fullfile(obj.schfigdir, '.schfigname'), 'wt');
        fprintf(fid, '%s', val);
        fclose(fid);

    end

    function obj = set.dims(obj, val)

        % the user set it like Bob Villa,
        if isa(val, 'char') & contains(lower(val), 'x')
            nums = regexp(val, 'x', 'split');

            if length(nums) == 2
                % we could add additional checks here but I really don't care
                nums = cellfun(@str2num, nums);
                obj.dims = nums;

            else
                fprintf('Check string formatting [expected nxn]...\n');
                return;
            end

        elseif isnumeric(val) & length(val) == 2
            obj.dims = val;
        end

        % set dimensions yo

        pos = obj.fig.Position;
        obj.fig.Position = [pos(1:2) obj.dims(:)'];
        obj.fig.PaperSize = [obj.dims(:)'];
    end

    function obj = set.renderer(obj, val)
        obj.fig.Renderer = val;
        obj.renderer = val;
    end

    function obj = set.formats(obj, val)
        obj.formats = val;
    end

    function obj = set.working_dir(obj, val)
        % schfigurate it

        if exist(val, 'dir')
            fid = fopen(fullfile(obj.schfigdir, '.schfigrectory'), 'wt');
            fprintf(fid, '%s', val);
            fclose(fid);
            obj.working_dir = val;
        end

    end

    function obj = set.units(obj, val)
        obj.fig.Units = val;
        obj.fig.PaperUnits = val;
        obj.units = val;
    end

end

methods (Static)
    sparsify_axis(ax, precision, xy, xtick, ytick)
    outify_axis(ax, tick_length)
    unify_caxis(ax, precision)
    h = shaded_errorbar(x, y, facecolor, edgecolor, method)
    [box_handle, med_handle, whisk_handle] = boxplot(data, grps, varargin)
    [h, xdata, ydata] = stair_histogram(x, bins, varargin)
    h = scatter_density(x, y, density, smoothing)
    h = group_violin(data, varargin)
    h = plot_trace_with_ci(x, data, boots, varargin)
end

end

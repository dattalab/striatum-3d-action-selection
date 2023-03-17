function animate_data(OBJ, FRAMES, HIGH_PASS, MISC, FILENAME)
%
%
%
%

if nargin < 3
    HIGH_PASS = false;
end

if nargin < 5
    FILENAME = [];
end

if nargin < 4
    MISC = [];
end

% prepare the data for plotting

%whitebg(gcf,[0 0 0])
fig = gcf;
clf(fig);
set(fig, 'Color', [0 0 0], 'Position', [200 200 800 550]);

frame_width = 500;
plot_photometry = true;

if OBJ.status.neural_photometry & plot_photometry

    traces = cat(2, OBJ.neural_data.photometry.traces([1 4]).dff);
    %tau=[.5 1];

    if HIGH_PASS
        nans = isnan(traces);
        traces(nans) = 0;
        [b, a] = ellip(3, .2, 40, [.5] / (OBJ.neural_data.photometry.metadata.fs / 2), 'high');
        traces = filtfilt(b, a, traces);
        traces(nans) = nan;
    end

    %
    % for i=1:size(traces,2)
    % 	kernel=(ones(1,20)*tau(i)).^[1:20];
    % 	kernel=kernel./sum(kernel);
    % 	traces(:,i)=conv(traces(:,i),kernel,'same');
    % end
    traces = phanalysis.nanzscore(traces);
    traces(FRAMES) = phanalysis.nanzscore(traces(FRAMES));

end

plot_shrouds = [];
plot_traces = [];
plot_traces_data = [];
plot_ims = [];
plot_ims_data = {};

depth_bounded_rotated = OBJ.load_oriented_frames('raw', true);
depth_bounded_rotated(depth_bounded_rotated < 10) = 0;
ax_mouse = axes('ydir', 'rev', 'units', 'pixels', 'position', [25 200 160 160]);
h_mouse = imagesc(depth_bounded_rotated(:, :, FRAMES(1)), 'parent', ax_mouse); caxis([0 40]);
colormap(ax_mouse, jet);
%freezeColors(ax_mouse);
axis(ax_mouse, 'off');

ax = [];

rps = OBJ.get_original_timebase(OBJ.projections.rp)';
ax(end + 1) = axes('units', 'pixels', 'position', [300 350 450 150]);
plot_ims(end + 1) = imagesc(rps(:, FRAMES(1):FRAMES(1) + frame_width), 'parent', ax(end));
plot_ims_data{end + 1} = rps;
plot_shrouds(end + 1) = patch([0 frame_width + 1 frame_width 0], [1 1 size(rps, 1) size(rps, 1)], 0, 'facecolor', [0 0 0], 'edgecolor', 'none');
caxis([-2 2]);
colormap(ax(end), bone)
%freezeColors(ax1);
axis(ax(end), 'off');
set(ax(end), 'xlim', [1 frame_width]);

%score_plot=filter(ones(5,1)/5,1,zscore(scores(:,:)))+repmat([size(scores,2):-1:1]*2,[size(scores,1) 1]);
% score_plot=zscore(OBJ.get_original_timebase(OBJ.projections.rp_changepoint_score));
% plot_traces_data(end+1,:)=score_plot;
% ax(end+1)=axes('units','pixels','position',[300 225 450 100]);
% plot_traces(end+1)=plot(score_plot(FRAMES(1):FRAMES(1)+frame_width),'linewidth',1.5,'color','w');
% set(ax(end),'YDir','rev');
% ylim([0 4]);
% ylimits=ylim(ax(end));
% plot_shrouds(end+1)=patch([0 frame_width+1 frame_width+1 0],[ ylimits(1) ylimits(1) ylimits(2) ylimits(2) ],0,'facecolor',[0 0 0],'edgecolor','none');
% axis(ax(end),'off');
% set(ax(end),'xlim',[1 frame_width]);

ax(end + 1) = axes('units', 'pixels', 'position', [300 300 450 50]);
labels = OBJ.behavior_model.labels(:)';
plot_ims(end + 1) = imagesc(labels(:, FRAMES(1):FRAMES(1) + frame_width), 'parent', ax(end));
plot_ims_data{end + 1} = labels;
ylimits = ylim();

plot_shrouds(end + 1) = patch([0 frame_width + 1 frame_width 0], [ylimits(1) ylimits(1) ylimits(2) ylimits(2)], 0, 'facecolor', [0 0 0], 'edgecolor', 'none');
%caxis([-2 2]);
caxis([0 100]);
colormap(ax(end), distinguishable_colors(length(unique(labels))))
%freezeColors(ax2);
axis(ax(end), 'off');
set(ax(end), 'xlim', [1 frame_width]);

%traces(FRAMES(1):FRAMES(2))=zscore(traces(FRAMES(1):FRAMES(2)));
% better color palette here?

colors = {'g', 'r', 'm', 'y'};

if OBJ.status.neural_photometry & plot_photometry
    ax(end + 1) = axes('units', 'pixels', 'position', [300 150 450 150]);
    hold on;

    for i = 1:size(traces, 2)
        plot_traces_data(end + 1, :) = traces(:, i);
        plot_traces(end + 1) = plot(traces(FRAMES(1):FRAMES(1) + frame_width, i), 'linewidth', 1.5, 'color', colors{i});
    end

    limits = [];
    tmp = traces(FRAMES, :);
    limits(1) = floor([prctile(tmp(:), .5)])
    limits(2) = ceil([prctile(tmp(:), 99.5)])

    %ylim([limits]);
    ylimits = ylim(ax(end));
    plot_shrouds(end + 1) = patch([0 frame_width + 1 frame_width + 1 0], [ylimits(1) - .001 ylimits(1) - .001 ylimits(2) ylimits(2)], 0, 'facecolor', [0 0 0], 'edgecolor', 'none');
    axis(ax(end), 'off');
    set(ax(end), 'xlim', [1 frame_width]);

end

if ~isempty(MISC)

    % if the user passes another traces, plot that ish too

    ax(end + 1) = axes('unit', 'pixels', 'position', [300 25 450 125])

    for i = 1:size(MISC, 2)
        plot_traces_data(end + 1, :) = MISC(:, i);
        plot_traces(end + 1) = plot(MISC(FRAMES(1):FRAMES(1) + frame_width, i), 'color', colors{i}, 'linewidth', 1.5);
        hold on;
    end

    %ylim([min(MISC(FRAMES)) max(MISC(FRAMES))])
    ylimits = ylim(ax(end))
    plot_shrouds(end + 1) = patch([0 frame_width + 1 frame_width + 1 0], [ylimits(1) - .001 ylimits(1) - .001 ylimits(2) ylimits(2)], 0, 'facecolor', [0 0 0], 'edgecolor', 'none');
    axis(ax(end), 'off');
    set(ax(end), 'xlim', [1 frame_width]);

end

linkaxes(ax, 'x');

% TODO xcorr goes here

if ~isempty(FILENAME)
    v = VideoWriter([FILENAME], 'mpeg-4');
    v.FrameRate = 30;
    v.Quality = 100;
    open(v);
end

timer_upd = kinect_extract.proc_timer(length(FRAMES), 'frequency', 50);

for i = FRAMES

    set(h_mouse, 'CData', depth_bounded_rotated(:, :, i));

    if (i - (FRAMES(1) - 1)) <= frame_width

        for j = 1:length(plot_shrouds)
            set(plot_shrouds(j), 'xdata', [i - (FRAMES(1) - 1) frame_width + 1 frame_width + 1 i - (FRAMES(1) - 1)]');
        end

    else

        for j = 1:length(plot_ims)
            set(plot_ims(j), 'cdata', plot_ims_data{j}(:, i - frame_width:i));
        end

        for j = 1:length(plot_traces)
            set(plot_traces(j), 'ydata', plot_traces_data(j, (i - frame_width:i)));
        end

        %set(h2_score,'ydata',score_plot(i-frame_width:i));
        %for j=1:length(h3_traces)
        %	set(h3_traces(j),'ydata',traces(i-frame_width:i,1));
        %end
    end

    if ~isempty(FILENAME)
        im = getframe(fig);
        writeVideo(v, im.cdata);
        pause(eps);
    else
        pause(.03);
    end

    timer_upd(i - (FRAMES(1) - 1));
end

if ~isempty(FILENAME)
    close(v)
end

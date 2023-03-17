function kinect_preview_tool(DATA, MEM_VAR, FEATURES, FRAMES, TRACES)
% This is meant to scroll through movies of the bounded mouse with other
% data, e.g. PCs, random projections, spinograms, photometry.  Run this
% after kinect_prepare_analysis.
%
%
% Example:
% >> cd ~/session_20160509171440/proc;
% >> kinect_track;
% >> kinect_getstats;
% >> kinect_bound;
% >> kinect_orient;
%	>> kinect_flip_tool;
% >> kinect_prepare_analysis;

colors = 'parula';
use_frames = 5e2;
auto_lims = [0 inf];
auto_per = [2.5 97.5];

if nargin < 5
    TRACES = [];
end

if nargin < 4 | isempty(FRAMES)

    if exist('analysis/frames.mat', 'file')
        FRAMES = 'analysis/frames.mat';
    else
        FRAMES = fullfile(pathname, filename);
    end

end

load(FRAMES, 'recon');

if nargin < 3 | isempty(FEATURES)

    if exist('analysis/features.mat', 'file')
        FEATURES = 'analysis/features.mat';
    else
        FEATURES = fullfile(pathname, filename);
    end

end

load(FEATURES, 'features');

if nargin < 2 | isempty(MEM_VAR)
    MEM_VAR = 'depth_bounded_rotated';
end

if nargin < 1 | isempty(DATA)

    if exist('depth_bounded.mat', 'file')
        DATA = fullfile(pwd, 'depth_bounded_rotated.mat');
    else
        [filename, pathname] = uigetfile('*.mat');
        DATA = fullfile(pathname, filename);
    end

end

% TODO: load flip file automatically
% TODO: marker indicating current frame on flip record

im_memmap = matfile(DATA);
[height, width, nframes] = size(im_memmap, MEM_VAR);

tmp = im_memmap.(MEM_VAR)(:, :, 1:min(nframes, use_frames));

clims = prctile(double(tmp(tmp > auto_lims(1) & tmp < auto_lims(2))), auto_per);

% set up figure panel with a slider, button to label flips

flip_record = uint8(zeros(1, nframes));
fig_handles.main = figure('resize', 'on');
set(fig_handles.main, 'DoubleBuffer', 'off');

setappdata(fig_handles.main, 'frame_number', 0);

axis_handles.im = axes('xlimmode', 'manual', 'ylimmode', 'manual', ...
    'zlimmode', 'manual', 'climmode', 'manual', 'alimmode', 'manual', ...
    'position', [.05 .6 .8 .3]);
plot_handles.im = imagesc(im_memmap.(MEM_VAR)(:, :, 1), 'parent', axis_handles.im);
plot_handles.im_title = title(['Frame 1']);
axis(axis_handles.im, 'off');
caxis(clims);

% spinogram

axis_handles.spines = axes('xlimmode', 'manual', 'ylimmode', 'manual', ...
    'zlimmode', 'manual', 'climmode', 'manual', 'alimmode', 'manual', ...
    'position', [.05 .45 .8 .1]);
data_handles.spines = imagesc(squeeze(mean(recon(30:50, :, :))));
ylims = ylim(axis_handles.spines);
change_handles(1) = line([1 1], [ylims], 'color', 'k');
caxis([0 50]);
axis(axis_handles.spines, 'off');
set(axis_handles.spines, 'xlim', [1 nframes]);

% rps

axis_handles.rps = axes('xlimmode', 'manual', 'ylimmode', 'manual', ...
    'zlimmode', 'manual', 'climmode', 'manual', 'alimmode', 'manual', ...
    'position', [.05 .35 .8 .1]);
data_handles.rps = imagesc(zscore(zscore(features.rps'))');
ylims = ylim(axis_handles.rps);
change_handles(2) = line([1 1], [ylims], 'color', 'k');
caxis([-4 4]);
axis(axis_handles.rps, 'off');
set(axis_handles.rps, 'xlim', [1 nframes]);
% pcs

axis_handles.pcs = axes('xlimmode', 'manual', 'ylimmode', 'manual', ...
    'zlimmode', 'manual', 'climmode', 'manual', 'alimmode', 'manual', ...
    'position', [.05 .25 .8 .1]);
%data_handles.pcs=imagesc(zscore(features.scores')');
data_handles.pcs = plot(zscore(features.scores(1:3, :)'));
ylims = ylim(axis_handles.pcs);
change_handles(3) = line([1 1], [ylims], 'color', 'k');
axis(axis_handles.pcs, 'off');
set(axis_handles.pcs, 'xlim', [1 nframes]);

if ~isempty(TRACES)
    axis_handles.traces = axes('xlimmode', 'manual', 'ylimmode', 'manual', ...
        'zlimmode', 'manual', 'climmode', 'manual', 'alimmode', 'manual', ...
        'position', [.05 .15 .8 .1]);
    data_handles.traces = plot(TRACES);
    ylims = ylim(axis_handles.traces);
    change_handles(4) = line([1 1], [ylims], 'color', 'k');
    axis(axis_handles.traces, 'off');
    set(axis_handles.traces, 'xlim', [1 nframes]);
end

control_handles.slider = uicontrol(fig_handles.main, 'Style', 'slider', 'Min', 1, 'Max', nframes, ...
    'SliderStep', [1 / nframes 10 / nframes], 'Value', 1, ...
    'Units', 'Normalized', 'Position', [.05 .55 .8 .04]);
addlistener(control_handles.slider, 'ContinuousValueChange', ...
    @(hObject, event) slider_callback(hObject, event, im_memmap, MEM_VAR, plot_handles, change_handles, fig_handles.main));

% spinogram, pcs, rps, and optionally traces???

% we probably want playback, control of playback speed, rewind and fast-forward

end

function slider_callback(hObject, eventdata, data, mem_var, im_handles, change_handles, fig)
%

val = get(hObject, 'Value');
frame_change(data, mem_var, round(val), im_handles, change_handles, fig);

end

function play_callback(hObject, eventdata, data, mem_var, im_handle)

% loop through until another button is depressed

end

function frame_change(data, mem_var, frame_number, im_handles, change_handles, fig)

% set cdata and frame number

set(im_handles.im, 'cdata', data.(mem_var)(:, :, frame_number));
setappdata(fig, 'frame_number', frame_number);
set(im_handles.im_title, 'string', sprintf('Frame %i', frame_number));

% loop through all plots beneath
for i = 1:length(change_handles)
    set(change_handles(i), 'xdata', [frame_number frame_number]);
end

end

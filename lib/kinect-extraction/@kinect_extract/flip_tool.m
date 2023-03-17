function flip_tool(OBJ)
% Initializes a simple GUI for marking flips in oriented data, use this
% to curate a dataset for training a flip classifier
%

colors = 'parula';
use_frames = 5e2;
auto_lims = [0 100];
auto_per = [2.5 97.5];

if ~OBJ.status.orient
    fprintf('Need to orient mouse first.\n');
    return;
end

mem_var = [OBJ.options.orient.mem_var '_rotated'];
im_memmap = matfile(OBJ.files.orient{1});
[height, width, nframes] = size(im_memmap, mem_var);

tmp = im_memmap.(mem_var)(:, :, 1:min(nframes, use_frames));

clims = prctile(double(tmp(tmp > auto_lims(1) & tmp < auto_lims(2))), auto_per);

% set up figure panel with a slider, button to label flips

flip_record = uint8(zeros(1, nframes));
fig_handles.main = figure('resize', 'on', 'MenuBar', 'none', 'Toolbar', 'none', 'color', [0 0 0]);
set(fig_handles.main, 'DoubleBuffer', 'off');

setappdata(fig_handles.main, 'frame_number', 1);
setappdata(fig_handles.main, 'flip_record', flip_record);

axis_handles.im = axes('xlimmode', 'manual', 'ylimmode', 'manual', ...
    'zlimmode', 'manual', 'climmode', 'manual', 'alimmode', 'manual', ...
    'position', [.05 .11 .5 .82]);
plot_handles.im = imagesc(im_memmap.(mem_var)(:, :, 1), 'parent', axis_handles.im);
plot_handles.im_title = title(['Frame 1'], 'color', [1 1 1]);
axis(axis_handles.im, 'off');
caxis(clims);

axis_handles.pos = axes('xlimmode', 'manual', 'ylimmode', 'manual', ...
    'position', [.6 .86 .35 .05]);
plot_handles.pos = line([0 0], [0 1], 'parent', axis_handles.pos, 'color', [1 0 0]);
axis(axis_handles.pos, 'off');
set(axis_handles.pos, 'ylim', [.1 1], 'xlim', [-2 length(flip_record) + 2]);

axis_handles.rec = axes('xlimmode', 'manual', 'ylimmode', 'manual', ...
    'position', [.6 .8 .35 .05]);
plot_handles.rec = stairs(flip_record, 'parent', axis_handles.rec, 'color', [1 1 1]);
set(axis_handles.rec, 'ylim', [.1 1], 'xlim', [-5 length(flip_record) + 5], ...
    'ytick', [], 'ycolor', [1 0 0], 'xcolor', [1 0 0], 'xtick', [], ...
    'TickLength', [0 0], 'color', get(fig_handles.main, 'color'));
xlabel(axis_handles.rec, 'Flips');
%title('Flips');

control_handles.slider = uicontrol(fig_handles.main, 'Style', 'slider', 'Min', 1, 'Max', nframes, ...
    'SliderStep', [1 / nframes 10 / nframes], 'Value', 1, ...
    'Units', 'Normalized', 'Position', [.05 .05 .5 .05]);
addlistener(control_handles.slider, 'ContinuousValueChange', ...
    @(hObject, event) slider_callback(hObject, event, im_memmap, mem_var, plot_handles, fig_handles.main));

control_handles.prev_flip = uicontrol(fig_handles.main, 'Style', 'PushButton', ...
    'Units', 'Normalized', 'Position', [.6 .65 .11 .1], ...
    'String', 'Next Flip');
set(control_handles.prev_flip, ...
    'Callback', {@goto_flip, im_memmap, mem_var, plot_handles, control_handles, fig_handles.main, true});

control_handles.next_flip = uicontrol(fig_handles.main, 'Style', 'PushButton', ...
    'Units', 'Normalized', 'Position', [.72 .65 .11 .1], ...
    'String', 'Prev. Flip');
set(control_handles.next_flip, ...
    'Callback', {@goto_flip, im_memmap, mem_var, plot_handles, control_handles, fig_handles.main, false});

control_handles.del_flip = uicontrol(fig_handles.main, 'Style', 'PushButton', ...
    'Units', 'Normalized', 'Position', [.84 .65 .11 .1], ...
    'String', 'Del. Flip');
set(control_handles.del_flip, ...
    'Callback', {@delete_flip, plot_handles, fig_handles.main});

control_handles.mark = uicontrol(fig_handles.main, 'Style', 'PushButton', ...
    'Units', 'Normalized', 'Position', [.6 .5 .35 .1], ...
    'String', 'Mark Flip');
set(control_handles.mark, 'Callback', {@mark_flips, plot_handles, fig_handles.main});

control_handles.save = uicontrol(fig_handles.main, 'Style', 'PushButton', ...
    'Units', 'Normalized', 'Position', [.6 .3 .15 .1], ...
    'String', 'Save Flip(s)');
set(control_handles.save, 'Callback', {@save_flips, fig_handles.main, OBJ});

control_handles.load = uicontrol(fig_handles.main, 'Style', 'PushButton', ...
    'Units', 'Normalized', 'Position', [.8 .3 .15 .1], ...
    'String', 'Load Flip(s)');
set(control_handles.load, 'Callback', {@load_flips, plot_handles, fig_handles.main, OBJ});

% we probably want playback, control of playback speed, rewind and fast-forward

if OBJ.files.flip{2}
    load_flips([], [], plot_handles, fig_handles.main, OBJ);
end

end

function slider_callback(hObject, eventdata, data, mem_var, handles, fig)
%

val = get(hObject, 'Value');
frame_change(data, mem_var, round(val), handles, fig);

end

function play_callback(hObject, eventdata, data, mem_var, im_handle)

% loop through until another button is depressed

end

function frame_change(data, mem_var, frame_number, handles, fig)

% set cdata and frame number

set(handles.im, 'cdata', data.(mem_var)(:, :, frame_number));
setappdata(fig, 'frame_number', frame_number);
set(handles.im_title, 'string', sprintf('Frame %i', frame_number));
set(handles.pos, 'xdata', [frame_number frame_number]);

end

function mark_flips(hObject, eventdata, handles, fig)

tmp = getappdata(fig, 'frame_number');
tmp_rec = getappdata(fig, 'flip_record');

if tmp > 0 & tmp <= length(tmp_rec)
    tmp_rec(tmp) = 1;
    setappdata(fig, 'flip_record', tmp_rec);
    set(handles.rec, 'Xdata', [1:length(tmp_rec)], 'YData', tmp_rec);
end

end

function goto_flip(hObject, eventdata, data, mem_var, plot_handles, control_handles, fig, prev)

% go to the nearest flip in the forward and reverse directions

tmp = getappdata(fig, 'frame_number');
tmp_rec = getappdata(fig, 'flip_record');
flips = find(tmp_rec);
dist = tmp - flips;

if prev
    flips(dist >= 0) = [];
    [~, idx] = min(abs(dist(dist < 0)));
else
    flips(dist <= 0) = [];
    [~, idx] = min(abs(dist(dist > 0)));
end

if ~isempty(idx)
    set(control_handles.slider, 'value', flips(idx));
    frame_change(data, mem_var, flips(idx), plot_handles, fig);
    setappdata(fig, 'frame_number', flips(idx));
end

end

function save_flips(hObject, eventdata, fig, kObject)

% save to a csv file and be done with it!

tmp_rec = getappdata(fig, 'flip_record');
flips = find(tmp_rec);

% write em out, comma delimited I say!

fid = fopen(kObject.files.flip{1}, 'wt');

if length(flips) > 0
    fprintf(fid, '%i', flips(1));

    for i = 2:length(flips)
        fprintf(fid, ',%i', flips(i));
    end

end

fclose(fid);

end

function load_flips(hObject, eventdata, plot_handles, fig, kObject)

% load em up, comma delimited I say again!

frames = read_flip_file(kObject.files.flip{1});
flip_record = getappdata(fig, 'flip_record');
flip_record = zeros(size(flip_record));
flip_record(frames) = 1;

setappdata(fig, 'flip_record', flip_record);
set(plot_handles.rec, 'Xdata', [1:length(flip_record)], 'YData', flip_record);

end

function delete_flip(hObject, evendata, plot_handles, fig)

% the current frame number is a flip, delete it!

tmp = getappdata(fig, 'frame_number');
flip_record = getappdata(fig, 'flip_record');
flips = find(flip_record);

if any(tmp == flips)
    flips(flips == tmp) = [];
    flip_record(tmp) = 0;
    setappdata(fig, 'flip_record', flip_record);
    set(plot_handles.rec, 'Xdata', [1:length(flip_record)], 'YData', flip_record);
end

end

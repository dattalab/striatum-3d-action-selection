function UPD = proc_timer(NLOOPS, varargin)
%
%
%

opts = struct( ...
    'frequency', 1, ...
    'width', 30, ...
    'marker', '=', ...
    'string_time', ' (%03id:%02ih:%02im:%02is remaining)');

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

start_time = tic;

%fprintf('\n');
string_prog = ['[', repmat(' ', [1 opts.width]), ']'];
template = [string_prog, sprintf(opts.string_time, 0, 0, 0, 0)];
fprintf(template);
string_len = length(template);

% nested function, first specify option

function UPDATE(LOOP)

    percent_complete = 100 * (LOOP / NLOOPS);

    if mod(LOOP, max(opts.frequency, 1)) == 0

        % get current time per loop, then mult by loops remaining

        time_per_loop = toc(start_time) / LOOP;
        tot_rem = time_per_loop * (NLOOPS - LOOP);

        days_rem = floor(tot_rem / 86400);
        hrs_rem = floor(mod(tot_rem, 86400) / 3600);
        mins_rem = floor(mod(tot_rem, 3600) / 60);
        secs_rem = floor(mod(tot_rem, 60));

        marker_width = round(percent_complete * opts.width / 100);
        empty_space = opts.width - marker_width;

        string_prog = ['[' repmat(opts.marker, [1 marker_width]) repmat(' ', [1 empty_space]) ']'];
        msg = [string_prog, sprintf(opts.string_time, days_rem, hrs_rem, mins_rem, secs_rem)];
        fprintf([repmat('\b', [1 string_len]), msg]);

    end

    if LOOP == NLOOPS
        fprintf('\n');
    end

end

%UPDATE(0);
UPD = @UPDATE;

end

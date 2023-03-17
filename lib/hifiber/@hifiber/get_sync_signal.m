function [PARAMS, FIT_FUN] = get_sync_signal(SIG, TS, SAMPLING_RATE)

SIG = conv(SIG, [ones(3, 1)], 'same');
TS = TS(~isnan(SIG));
SIG = SIG(~isnan(SIG));
SIG = SIG(:);

% it is possible we want to do this piece-wise, it's rare but sometimes
% the pulse train is off by a sample er so

sig_len = numel(SIG);
idx = 1:sig_len - 1;

pos_edges = find(SIG(idx) < .5 & SIG(idx + 1) >= .5);
period = mean(diff(pos_edges)) / SAMPLING_RATE;
fs = 1 ./ period;

duty_est = mean(dutycycle(SIG)) * 1e2;
init_params = [fs 0 duty_est];

ts = [0:sig_len - 1] / SAMPLING_RATE;
FIT_FUN = @(b, x) square(2 * pi * x * b(1) + b(2), b(3));
obj_fun = @(b) FIT_FUN(b, TS) - SIG;

[r, lags] = xcorr(SIG, FIT_FUN(init_params, TS), 20);
[~, loc] = max(r);
init_params(2) =- ((lags(loc) / SAMPLING_RATE) / period) * 2 * pi;

PARAMS = lsqnonlin(obj_fun, init_params, [init_params(1) - 10 -2 * pi 30], [init_params(1) + 10 2 * pi 80]);

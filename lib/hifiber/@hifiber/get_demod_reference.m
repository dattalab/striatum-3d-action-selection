function [PARAMS, FIT_FUN] = get_demod_reference(SIG, TS, SAMPLING_RATE, REF_FS, REF)

if nargin < 5
    REF = [];
end

if nargin < 5
    REF_FS = [];
end

SIG(isnan(SIG)) = 0;

sig_len = length(SIG);

if isempty(REF_FS)

    use_sig = SIG;
    use_sig(isnan(use_sig)) = 0;

    comp_fft = fft(use_sig - mean(use_sig));

    comp_fft = comp_fft(1:sig_len / 2 + 1);

    comp_fft(2:end - 1) = 2 * comp_fft(2:end - 1);

    mag_fft = abs(comp_fft / sig_len);
    mag_fft(1) = 0;
    phase_fft = mod(unwrap(angle(comp_fft)), 2 * pi);

    fvec = SAMPLING_RATE * [0:(sig_len / 2)] / sig_len;
    [~, loc] = max(mag_fft);

    % frequency guess

    freq_init = fvec(loc);
    phase_init = 0;

else

    freq_init = REF_FS; % filter and use zero cross something something for phase?
    phase_init = 0;

end

init_params = [nanstd(SIG) freq_init 0 nanmean(SIG)];

TS = TS(~isnan(SIG));
SIG = SIG(~isnan(SIG));

TS = TS(:);
SIG = SIG(:);

fprintf('Initial parameters: %g\n', init_params)

FIT_FUN = @(b, x) b(1) .* (sin(2 * pi * x * b(2) + b(3))) + b(4);
obj_fun = @(b) FIT_FUN(b, TS) - SIG;

init_fit_angle = angle(hilbert(FIT_FUN(init_params, TS)));
data_angle = angle(hilbert(SIG));
phase_diff = angle(mean(exp(1j .* (init_fit_angle(:) - data_angle(:)))));
init_params(3) = angle(exp(1j .* (-phase_diff))); % it's 0 to start, so just get angle diff from 0 dawg
opts = optimset('Display', 'off');
PARAMS = lsqnonlin(obj_fun, init_params, [init_params(1) * .75 freq_init - 20 -2 * pi 0], [init_params(2) * 1.25 freq_init + 20 2 * pi 1], opts);

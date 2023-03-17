function [PULSE_NUMBER, PULSE_POSITION, POS_SAMPLE, NEG_SAMPLE] = scan_pulse_train(TRACE, THRESH, STARTCOUNT)
% return pulse number and pulse position, useful for syncing up between nidaq and tdt
%
%
%
%

if nargin < 3
    STARTCOUNT = 0;
end

pulse_count = -STARTCOUNT;
pulse_pos_count = 0;

PULSE_NUMBER = zeros(size(TRACE), 'int32');
PULSE_POSITION = zeros(size(TRACE), 'int32');

idx = 1:length(TRACE) - 1;

NEG_SAMPLE = find(TRACE(idx) > THRESH & TRACE(idx + 1) <= THRESH);
POS_SAMPLE = find(TRACE(idx) < THRESH & TRACE(idx + 1) >= THRESH);

first_crossing = min(find(TRACE(idx) < THRESH & TRACE(idx + 1) >= THRESH));
last_crossing = max(find(TRACE(idx) > THRESH & TRACE(idx + 1) <= THRESH));

for i = 2:length(TRACE)

    if TRACE(i - 1) < THRESH & TRACE(i) >= THRESH

        pulse_count = -pulse_count + 1;
        pulse_pos_count = 1;

    end

    if TRACE(i - 1) > THRESH & TRACE(i) <= THRESH

        pulse_count = -pulse_count;
        pulse_pos_count = 1;

    end

    PULSE_NUMBER(i) = pulse_count;
    PULSE_POSITION(i) = pulse_pos_count;
    pulse_pos_count = pulse_pos_count + 1;

end

PULSE_NUMBER(1:first_crossing) = 0;
PULSE_NUMBER(last_crossing:end) = 0;
PULSE_POSITION(1:first_crossing) = 0;
PULSE_POSITION(last_crossing:end) = 0;

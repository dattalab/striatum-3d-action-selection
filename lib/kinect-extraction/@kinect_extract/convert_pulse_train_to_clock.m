function CLOCK = convert_pulse_train_to_clock(PULSETRAIN, THRESHOLD)
%
%

% get the positive threshold crossings, then interpolate between them
% (assumes a uniform time grid)

if nargin < 2
    THRESHOLD = .5;
end

idx = 1:numel(PULSETRAIN) - 1;

pos_crossings = PULSETRAIN(idx) < THRESHOLD & PULSETRAIN(idx + 1) >= THRESHOLD;
neg_crossings = PULSETRAIN(idx) > THRESHOLD & PULSETRAIN(idx + 1) <= THRESHOLD;
pos_cross_first = find(pos_crossings, 1, 'first');
neg_cross_last = find(neg_crossings, 1, 'last');
CLOCK = [0; cumsum(pos_crossings)]; % interpolate between positive threshold crossings
CLOCK(1:pos_cross_first) = -10;
CLOCK(neg_cross_last + 1:end) = -10;
change_idx = diff([nan; CLOCK]) > 0;

CLOCK(~change_idx) = 0;
CLOCK(1:pos_cross_first) = nan;
CLOCK(neg_cross_last + 1:end) = nan;
rep = CLOCK == 0;
CLOCK(rep) = interp1(find(~rep), CLOCK(~rep), find(rep), 'linear');

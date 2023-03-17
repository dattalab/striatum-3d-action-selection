function [ZPROFILE, VEL] = make_spinogram_average(OBJ, varargin)
%
%
%
%
%

opts = struct( ...
    'width', 40, ...
    'use_duration', [], ...
    'min_duration', 3, ...
    'process_frames', false, ...
    'min_examples', [], ...
    'syllable', 1, ...
    'depth', 673.1);

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

% for this particular syllable, get the mode, then average zprofiles and

% make a copy of the behavior object

beh = OBJ.get_behavior_object;
all_durs = [];

for i = 1:length(beh)
    all_durs = [all_durs; beh(i).state_durations{opts.syllable}];
end

if isempty(opts.use_duration)
    opts.use_duration = mode(all_durs(all_durs > opts.min_duration));
end

% loop through every object and grab the z and velocity profiles

use_examples = sum(all_durs == opts.use_duration);
ZPROFILE = nan(opts.width * 2, opts.use_duration + 1, use_examples);
VEL = nan(opts.use_duration + 1, use_examples);

counter = 1;

for i = 1:length(OBJ)
    use_idx = find(beh(i).state_durations{opts.syllable} == opts.use_duration);

    for j = 1:length(use_idx)
        [ZPROFILE(:, :, counter), VEL(:, counter)] = OBJ(i).make_spinogram('syllable', opts.syllable, ...
            'syllable_idx', use_idx(j), 'min_duration', [], 'process_frames', opts.process_frames);
        counter = counter + 1;
    end

end

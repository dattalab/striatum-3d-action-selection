function [USAGE, NORM_USAGE] = get_syllable_usage(OBJ, USE_FRAMES)
%
%

if nargin < 2
    USE_FRAMES = [1 inf];
end

for i = 1:length(OBJ)

    if ~isempty(OBJ(i).labels)
        nsyllables = numel(OBJ(i).states);
        break;
    end

end

USAGE = zeros(1, nsyllables);

for i = 1:length(OBJ)

    if isempty(OBJ(i).labels)
        continue;
    end

    nframes = length(OBJ(i).labels);
    use_frames = USE_FRAMES;

    if use_frames(2) > nframes
        use_frames(2) = nframes;
    end

    seq = OBJ(i).labels(use_frames(1):use_frames(2));
    seq = seq(find(diff(seq)));
    seq_len = length(seq);

    for j = 1:length(USAGE)
        USAGE(j) = USAGE(j) + sum(seq == OBJ(i).states(j));
    end

end

NORM_USAGE = USAGE ./ sum(USAGE);

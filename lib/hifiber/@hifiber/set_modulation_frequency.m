function set_modulation_frequency(OBJ, FREQ, CH)
%
%
%
%

if isfield(OBJ.metadata, 'tdt')

    % strip out channel names from fields

    tags = fieldnames(OBJ.metadata.tdt.tags);
    hits = regexp(tags, 'LED\d+Freq');
    idx = find(~cellfun(@isempty, hits));

    CH = nan(numel(idx), 1);
    FREQ = nan(size(CH));

    for i = 1:length(idx)
        tmp = regexp(tags{idx(i)}, '\d+', 'match');
        CH(i) = str2num(tmp{1});
        FREQ(i) = OBJ.metadata.tdt.tags.(tags{idx(i)});
        fprintf('Detected CH %i freq %i (Hz)\n', CH(i), FREQ(i));
    end

end

if length(FREQ) ~= length(CH)
    error('Need same number of frequencies and channels');
end

for i = 1:length(OBJ)

    for j = 1:length(CH)

        if CH(j) <= length(OBJ(i).traces)
            OBJ(i).traces(CH(j)).mod_freq = FREQ(j);
        end

    end

end

function remove_channels(OBJ, IDX, NAMES)
%
%
%
%

if nargin < 3
    NAMES = '';
end

if nargin < 2 | isempty(IDX)
    IDX = [];
end

if ~isempty(NAMES)
    to_rem = false(1, length(OBJ.metadata.channels));

    for i = 1:length(NAMES)
        idx = cellfun(@(x) ~isempty(x), strfind({OBJ.metadata.channels(:).name}, NAMES{i}));
        to_rem(idx) = true;
    end

else
    to_rem = IDX;
end

OBJ.traces(to_rem) = [];
%OBJ.metadata.channels(to_rem)=[];

% to_rem

function set_group(OBJ, GROUP)
%
%
%

if nargin < 2
    GROUP = [];
end

if ischar(GROUP)
    GROUP = {GROUP};
end

if ~iscell(GROUP)
    error('Groups must be cell array');
end

if length(GROUP) ~= length(OBJ)
    error('Length of groups and object vector must be the same');
end

for i = 1:length(GROUP)

    if isfield(OBJ(i).metadata, 'group')
        OBJ(i).metadata = rmfield(OBJ(i).metadata, 'group');
    end

    OBJ(i).metadata.groups = GROUP{i};
end

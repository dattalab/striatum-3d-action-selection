function set_group_include(OBJ, GROUP)
%
%
%

assert(lower(OBJ.data_type(1)) == 'p', 'Must be photometry data to proceed...')

if nargin < 2
    GROUP = 'odor';
end

groups = {OBJ.session(:).group};
group_only = contains(groups, GROUP);

for i = 1:length(group_only)
    OBJ.session(i).use_gcamp = group_only(i);
    OBJ.session(i).use_rcamp = group_only(i);
end

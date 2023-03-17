function CELL = kinect_map_parameters(STRUCT, CELL)
%
%
%
%

%tmp=kinect_read_options(CONFIG_FILE);

if nargin < 2 | isempty(CELL)
    CELL = {};
end

if nargin < 1 | isempty(STRUCT)
    CELL = {};
    return;
end

new_param_names = fieldnames(STRUCT);

for i = 1:length(new_param_names)
    CELL{end + 1} = new_param_names{i};
    CELL{end + 1} = STRUCT.(new_param_names{i});
end

% TODO: merge options

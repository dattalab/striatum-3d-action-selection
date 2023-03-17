function set_autoupdate(OBJ, SETTING)
%
%
%

if nargin < 2
    SETTING = true;
end

for i = 1:length(OBJ)
    OBJ(i).autoupdate = SETTING;
end

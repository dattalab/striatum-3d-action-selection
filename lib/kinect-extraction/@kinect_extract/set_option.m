function set_option(OBJ, CATEGORY, OPTION, OPTION_VAL);
% Makes sure the user sets options correctly
%
%
%

for i = 1:length(OBJ)

    if isfield(OBJ(i).options, CATEGORY)

        if isfield(OBJ(i).options.(CATEGORY), OPTION)
            use_class = class(OBJ(i).options.(CATEGORY).(OPTION));

            if isa(OPTION_VAL, use_class)
                OBJ(i).options.(CATEGORY).(OPTION) = OPTION_VAL;
            else
                fprintf('Option %s must be %s\n', OPTION, use_class);
            end

        else
            fprintf('No option %s in category, creating... %s\n', OPTION, CATEGORY);
            OBJ(i).options.(CATEGORY).(OPTION) = OPTION_VAL;
        end

    else
        fprintf('No category %s\n', CATEGORY);
    end

end

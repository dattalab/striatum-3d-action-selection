function set_option(OBJ, OPTION, OPTION_VAL);
% Makes sure the user sets options correctly
%
%
%

for i = 1:length(OBJ)

    if isfield(OBJ(i).options, OPTION)
        use_class = class(OBJ(i).options.(OPTION));

        if isa(OPTION_VAL, use_class)
            OBJ(i).options.(OPTION) = OPTION_VAL;
        else
            fprintf('Option %s must be %s\n', OPTION, use_class);
        end

    else
        fprintf('No option %s\n', OPTION);
    end

end

function kinect_print_options(RUN_OPTIONS)
%
%
%
%

fprintf('%s Options %s\n', repmat('#', [1 20]), repmat('#', [1 20]));

if ~iscell(RUN_OPTIONS)
    RUN_OPTIONS = kinect_map_parameters(RUN_OPTIONS);
end

for j = 1:2:length(RUN_OPTIONS)
    fprintf('Setting %s to:', RUN_OPTIONS{j});

    if isnumeric(RUN_OPTIONS{j + 1}) & ~isempty(RUN_OPTIONS{j + 1})

        for k = 1:length(RUN_OPTIONS{j + 1})
            fprintf(' %g', RUN_OPTIONS{j + 1}(k));
        end

    elseif iscell(RUN_OPTIONS{j + 1})

        for k = 1:length(RUN_OPTIONS{j + 1})
            fprintf(' %s', RUN_OPTIONS{j + 1}{k});
        end

    elseif islogical(RUN_OPTIONS{j + 1})

        if RUN_OPTIONS{j + 1}
            fprintf(' true');
        else
            fprintf(' false');
        end

    elseif isempty(RUN_OPTIONS{j + 1})
    elseif ischar(RUN_OPTIONS{j + 1})
        fprintf(' %s', RUN_OPTIONS{j + 1});
    else
        fprintf(' cannot print');
    end

    fprintf('\n');
end

fprintf('%s Options %s\n\n', repmat('#', [1 20]), repmat('#', [1 20]));

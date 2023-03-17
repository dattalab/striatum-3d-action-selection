function save_figure(OBJ)
%
%
%
%

% saving that figure like it's a figure to be saved

for i = 1:length(OBJ)
    renderer = sprintf('-%s', OBJ(i).renderer);
    res = sprintf('-r%i', OBJ(i).resolution);
    filename = fullfile(OBJ(i).working_dir, OBJ(i).name);
    pdf_gen = false;

    try

        if contains(OBJ(i).formats, 'eps') || contains(OBJ(i).formats, 'all')
            print(OBJ(i).fig, '-depsc2', renderer, sprintf('%s.eps', filename));
            % yeah MATLAB is REALLY EFFING GREAT AT MAKE NICE EPS files
            epsclean(sprintf('%s.eps', filename), sprintf('%s.eps', filename), false, true);

            if contains(OBJ(i).formats, 'pdf') || contains(OBJ(i).formats, 'all')
                [status, output] = system(sprintf('ps2pdf -dEPSCrop "%s.eps" "%s.pdf"', filename, filename));

                if status ~= 0
                    fprintf('%s', output)
                    error('Error generating pdf with ps2pdf')
                else
                    pdf_gen = true;
                end

            end

        end

        if contains(OBJ(i).formats, 'tiffn') || contains(OBJ(i).formats, 'all')
            print(OBJ(i).fig, '-dtiffn', renderer, sprintf('%s.tif', filename));

            if exist('rsetwrite') > 0
                disp('Writing rset...')
                rsetwrite(sprintf('%s.tif', filename), sprintf('%s.rset', filename));
                response = [];

                while isempty(response)
                    response = input('(K)eep the original .tiff or (d)elete?  ', 's');

                    switch lower(response(1))
                        case 'k'
                            break;
                        case 'd'
                            delete(sprintf('%s.tif', filename));
                        otherwise
                            response = [];
                    end

                end

            end

        end

        %print(OBJ(i).fig,'-dtiffn','-r300',fullfile(save_dir,[filename '.tif']));

        if contains(OBJ(i).formats, 'tiff') || contains(OBJ(i).formats, 'all')
            print(OBJ(i).fig, '-dtiff', renderer, res, sprintf('%s.tiff', filename));
        end

        if (contains(OBJ(i).formats, 'pdf') || contains(OBJ(i).formats, 'all')) & ~pdf_gen
            print(OBJ(i).fig, '-dpdf', renderer, res, sprintf('%s.pdf', filename));
        end

        if contains(OBJ(i).formats, 'png') || contains(OBJ(i).formats, 'all')
            print(OBJ(i).fig, '-dpng', renderer, res, sprintf('%s.png', filename));
        end

        if contains(OBJ(i).formats, 'svg') || contains(OBJ(i).formats, 'all')
            print(OBJ(i).fig, '-dsvg', renderer, res, sprintf('%s.svg', filename));
        end

        if contains(OBJ(i).formats, 'fig') || contains(OBJ(i).formats, 'all')
            saveas(OBJ(i).fig, sprintf('%s.fig', filename));
        end

    catch err
        rethrow(err)

        disp('Save did not work (running in terminal emulation?)...')

        if contains(OBJ(i).formats, 'eps') || contains(OBJ(i).formats, 'all')
            print(OBJ(i).fig, '-depsc2', renderer, '-r100', sprintf('%s.eps', filename));
        end

        if contains(OBJ(i).formats, 'png') || contains(OBJ(i).formats, 'all')
            print(OBJ(i).fig, '-dpng', renderer, '-r100', sprintf('%s.png', filename));
        end

        if contains(OBJ(i).formats, 'fig') || contains(OBJ(i).formats, 'all')
            saveas(OBJ(i).fig, sprintf('%s.fig', filename));
        end

    end

end

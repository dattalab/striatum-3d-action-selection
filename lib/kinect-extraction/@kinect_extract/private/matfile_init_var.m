function MATFILE = kinect_matfile_initvar(MATFILE, CLASS, varargin)
%
%
%
%

% yup, do it the dumb way...(i.e. the most straightforward way to avoid eval)
for i = 1:2:length(varargin)

    if length(varargin{i + 1}) == 3

        switch lower(CLASS)
            case 'int16'
                MATFILE.(varargin{i})(varargin{i + 1}(1), varargin{i + 1}(2), varargin{i + 1}(3)) = int16(0);
            case 'int8'
                MATFILE.(varargin{i})(varargin{i + 1}(1), varargin{i + 1}(2), varargin{i + 1}(3)) = int8(0);
            case 'uint16'
                MATFILE.(varargin{i})(varargin{i + 1}(1), varargin{i + 1}(2), varargin{i + 1}(3)) = uint16(0);
            case 'uint8'
                MATFILE.(varargin{i})(varargin{i + 1}(1), varargin{i + 1}(2), varargin{i + 1}(3)) = uint8(0);
            case 'double'
                MATFILE.(varargin{i})(varargin{i + 1}(1), varargin{i + 1}(2), varargin{i + 1}(3)) = double(0);
            case 'single'
                MATFILE.(varargin{i})(varargin{i + 1}(1), varargin{i + 1}(2), varargin{i + 1}(3)) = single(0);
        end

    elseif length(varargin{i + 1}) == 2

        switch lower(CLASS)
            case 'int16'
                MATFILE.(varargin{i})(varargin{i + 1}(1), varargin{i + 1}(2)) = int16(0);
            case 'int8'
                MATFILE.(varargin{i})(varargin{i + 1}(1), varargin{i + 1}(2)) = int8(0);
            case 'uint16'
                MATFILE.(varargin{i})(varargin{i + 1}(1), varargin{i + 1}(2)) = uint16(0);
            case 'uint8'
                MATFILE.(varargin{i})(varargin{i + 1}(1), varargin{i + 1}(2)) = uint8(0);
            case 'double'
                MATFILE.(varargin{i})(varargin{i + 1}(1), varargin{i + 1}(2)) = double(0);
            case 'single'
                MATFILE.(varargin{i})(varargin{i + 1}(1), varargin{i + 1}(2)) = single(0);
        end

    end

end

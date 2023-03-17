function set_include_manual(OBJ, IDX, VALUE, FIELD)
%
%
%

if nargin < 4
    FIELD = '';
end

if nargin < 3 | isempty(VALUE)
    VALUE = true;
end

if nargin < 2 | isempty(IDX)
    IDX = 1:length(OBJ.session);
end

for i = 1:length(IDX)

    if isempty(FIELD)
        OBJ.session(IDX(i)).use_gcamp = VALUE;
        OBJ.session(IDX(i)).use_rcamp = VALUE;
    else
        OBJ.session(IDX(i)).(FIELD) = VALUE;
    end

    if lower(OBJ.data_type == 'p')
        OBJ.session(IDX(i)).has_photometry = true;
    end

end

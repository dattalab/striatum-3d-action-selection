function NEW_COPY = copy(OBJ)
%
%
%

NEW_COPY = feval(class(OBJ));
p = properties(OBJ);

for i = 1:length(p)
    NEW_COPY.(p{i}) = OBJ.(p{i});
end

function update_status(OBJ)
% Updates the progress status

FLAGS = [];
MOVIE_FLAGS = [];

% is the data even extracted?

OBJ.status.pcs_computed = ~isempty(OBJ.coeffs);

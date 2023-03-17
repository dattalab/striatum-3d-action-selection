function get_all_projections(OBJ)
%
%
%

OBJ.compute_pcs;
OBJ.apply_pcs;
OBJ.compute_rps;
OBJ.compute_scalars;
OBJ.compute_changepoint_score;

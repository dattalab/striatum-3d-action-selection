function [MU, COV] = kinect_online_covariance(DATA, MU, COV)
%
%
%
%
%
%
%
opts = struct( ...
    'eta_buffer', 10, 'eta_counter', 1);

% streaming version of covariance estimation

if nargin < 2 | isempty(MU)
    MU = 0;
end

if nargin < 3 | isempty(COV)
    COV = 0;
end

[nfeatures, nobservations] = size(DATA);
time_buffer = nan(opts.eta_buffer, 1);

for i = 1:nobservations
    %
    % if i==1
    % 	[proc_time time_rem rev_string time_buffer]=kinect_proctimer(...
    % 		i,nobservations,opts.eta_counter,time_buffer);
    % else
    % 	[proc_time time_rem rev_string time_buffer]=kinect_proctimer(...
    % 		i,nobservations,opts.eta_counter,time_buffer,proc_time,time_rem,rev_string);
    % end

    cur_observation = DATA(:, i);
    delta = (cur_observation - ones(nfeatures, 1) .* MU) ./ i;
    MU = MU + delta;
    COV = COV + (i - 1) * delta * delta' - COV / i;

end

COV = COV * (nobservations / (nobservations - 1));

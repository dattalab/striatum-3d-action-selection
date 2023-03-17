function FLIPS=angle_fix_ctrax(ANGLES,CENTROIDS)
% Given angles and centroids, uses the dynamic programming algorithm
% proposed by Branson et al. (ported from the Ctrax implementation)
%
%
%

max_vel_angle_weight=.2;
vel_angle_weight=5e-3;

vx=diff(CENTROIDS(:,1));
vy=diff(CENTROIDS(:,2));

% get velocity magnitude and angle

vel_mag=hypot(vx,vy);
vel_ang=mod(atan2(-vy,vx),2*pi);

nframes=numel(ANGLES);

state_prev=zeros(nframes-1,3,'logical');
cost_prev_new=zeros(3,1);
cost_prev=zeros(3,1);
tmp_cost=zeros(3,1);

for i=2:nframes

	curr_mag=vel_mag(i-1)
	curr_ang=vel_ang(i-1);
	w=min(max_vel_angle_weight,vel_angle_weight*curr_mag);

	for j=0:2

		%theta_curr=mod(ANGLES(i)+j*pi+pi,2*pi)-pi;
		theta_curr=mod(ANGLES(i)+j*pi/2,2*pi);
		for k=0:2

			%theta_prev=mod(ANGLES(i-1)+k*pi+pi,2*pi)-pi;
			theta_prev=mod(ANGLES(i-1)+k*pi/2,2*pi);
			curr_cost=(1-w)*angle_dist(theta_prev,theta_curr)+...
				w*angle_dist(theta_curr,curr_ang);
				% theta_curr
				% curr_mag
				% curr_ang
				% angle_dist(theta_curr,curr_ang)
				% i
				% pause();
			tmp_cost(k+1)=cost_prev(k+1)+curr_cost;
			% theta_curr
			% theta_prev
			% curr_ang
			% curr_mag
			% curr_cost
			% angle_dist(theta_prev,theta_curr)
			% angle_dist(theta_curr,curr_ang)
			% pause();
		end

		[~,idx]=min(tmp_cost);
		state_prev(i-1,j+1)=idx-1;
		cost_prev_new(j+1)=tmp_cost(idx);

	end

	cost_prev=cost_prev_new;

	% work backwards from cost_prev_new

end

cost_prev_new
pause();
[~,idx]=min(cost_prev_new)

idx=idx-1;
flip_vec=[];
state_prev
idx
for i=nframes-1:-1:1
		idx=state_prev(i,idx+1);
		if idx>0
			ANGLES(i)=ANGLES(i)+idx*pi/2;
			flip_vec=[flip_vec i];
		end
end

flip_vec(abs(diff([-inf flip_vec]))>1)

end

function DIST=angle_dist(THETA1,THETA2)


%DIST=abs(mod((THETA1-THETA2),2*pi));
DIST=abs(angle(exp(1j.*(THETA1-THETA2))));

end

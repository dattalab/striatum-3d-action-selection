%%


if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/photometry_dls/phanalysis_object.mat');
    phan=phanalysis_object;
end

if ~exist('model_starts','var')
    phan.set_option('normalize_method','');
    phan.set_option('rectify',false);
    phan.set_option('filter_trace',false);
    model_starts=phan.slice_syllables_neural;    
end

if ~exist('ave_starts_warped','var')
    ave_starts=phan.average_windows(model_starts,'normalize',false);
    ave_starts_warped=phan.average_windows(model_starts,...
        'normalize',true,...
        'time_warp',true,...
        'warp_dur',20,...
        'warp_shift',[0 0]);
end

if ~exist('gcamp_mu_rnd','var')
    load('~/Desktop/phanalysis_images/photometry_dls/modelr_randomizations_warped.mat');
end


%%

cut=phan.options.syllable_cutoff;

use_gcamp=(zscore(ave_starts.gcamp_mu.mu(:,1:cut)));
use_rcamp=(zscore(ave_starts.rcamp_mu.mu(:,1:cut)));

%use_gcamp=(zscore(tmp1(:,1:cut)));
%use_rcamp=(zscore(tmp2(:,1:cut)));
%use_rcamp=use_gcamp-use_rcamp;
max_lag=500;
use_samples_gcamp=[0 10];
use_samples_rcamp=[0 10];
offset=0;
use_lag=max_lag+offset;

use_mu_gcamp=use_gcamp(use_lag-use_samples_gcamp(1):use_lag+use_samples_gcamp(2),:);
use_mu_rcamp=use_rcamp(use_lag-use_samples_rcamp(1):use_lag+use_samples_rcamp(2),:);
% % 
% use_mu_gcamp=ave_starts_norm.gcamp_mu.mu(60:70,:);
% use_mu_rcamp=ave_starts_norm.rcamp_mu.mu(60:70,:);
use_mu_gcamp=([ave_starts_warped.gcamp_mu.mu(1:end,:);...
    ave_starts_warped.gcamp_mu.mu_dt(1:end,:)]);
use_mu_rcamp=([ave_starts_warped.rcamp_mu.mu(1:end,:);...
    ave_starts_warped.rcamp_mu.mu_dt(1:end,:)]);

% 
% use_mu_gcamp=([ave_starts_warped.gcamp_mu.mu(1:end,:)]);
% use_mu_rcamp=([ave_starts_warped.rcamp_mu.mu(1:end,:)]);


%dist_mat=phan.distance.inter.kl;
%use_idx=max(abs(use_gcamp))>=3.5&max(abs(use_rcamp))>=3.5;
%val=max(abs(use_rcamp));
%[~,test]=sort(val,'descend');

%use_idx=test(1:30); 
use_idx=1:cut;

distance=struct();
% 
% distance.jsd=sqrt(abs(squareform(phan.distance.inter.kl(use_idx,use_idx),'tovector')));
% distance.ar=abs(squareform(phan.distance.inter.ar(use_idx,use_idx),'tovector'));

use_scalars=fieldnames(phan.distance.inter.scalars);
scalar_idx=contains(use_scalars,{'velocity_mag','angle','height_ave'});
use_scalars=use_scalars(scalar_idx);

for i=1:length(use_scalars)
   distance.(use_scalars{i})=...
       squareform(phan.distance.inter.scalars.(use_scalars{i})(use_idx,use_idx),'tovector');
end

% rescale the distances, then combine

distance.ar=squareform(phan.distance.inter.ar(use_idx,use_idx),'tovector');
gcamp_use=use_mu_gcamp(:,use_idx);
rcamp_use=use_mu_rcamp(:,use_idx); 

distances={'correlation'};
rcamp_distance={};
gcamp_distance={};
both_distance={};
diff_distance={};

for i=1:length(distances) 
    
    rcamp_distance{i}=pdist((rcamp_use)',distances{i});
    gcamp_distance{i}=pdist((gcamp_use)',distances{i});
    both_distance{i}=pdist(([rcamp_use;gcamp_use])',distances{i});
    diff_distance{i}=pdist([zscore([rcamp_use;gcamp_use])' zscore([rcamp_use-gcamp_use])'],distances{i});

    [r_rcamp,p_rcamp]=corr(rcamp_distance{i}(:),(distance.ar(:)),'type','pearson','rows','pairwise');
    [r_gcamp,p_gcamp]=corr(gcamp_distance{i}(:),(distance.ar(:)),'type','pearson','rows','pairwise');
    [r_both,p_both]=corr(both_distance{i}(:),(distance.ar(:)),'type','pearson','rows','pairwise');
    [r_diff,p_diff]=corr(diff_distance{i}(:),(distance.ar(:)),'type','pearson','rows','pairwise');
    
    fprintf('%s distance: rcamp r=%g p=%g, gcamp r=%g p=%g, both r=%g p=%g, diff r=%g p=%g\n',...
           distances{i},r_rcamp,p_rcamp,r_gcamp,p_gcamp,r_both,p_both,r_diff,p_diff);
    
end

%%

r_both_rnd=[];

% if exist('gcamp_mu_rnd','var')
%     for i=1:size(gcamp_mu_rnd,3)
%         rcamp_use_rnd=rcamp_mu_rnd(use_lag-use_samples_rcamp(1):use_lag+use_samples_rcamp(2),:,i);
%         gcamp_use_rnd=gcamp_mu_rnd(use_lag-use_samples_gcamp(2):use_lag+use_samples_gcamp(2),:,i);
%         use_dist=pdist(zscore([rcamp_use_rnd;gcamp_use_rnd])','correlation');
%         r_both_rnd(i)=corr(use_dist(:),distance.ar(:),'type','pearson','rows','pairwise');
%     end
%     fprintf('\n\n');
% end

if exist('gcamp_mu_rnd','var')
    for i=1:size(gcamp_mu_rnd,3)
        rcamp_use_rnd=[rcamp_mu_rnd(:,:,i);rcamp_mu_dt_rnd(:,:,i)];
        gcamp_use_rnd=[gcamp_mu_rnd(:,:,i);gcamp_mu_dt_rnd(:,:,i)];
        %use_dist=pdist(zscore([rcamp_use_rnd;gcamp_use_rnd])','correlation');
        use_dist=pdist([rcamp_use_rnd;gcamp_use_rnd]','correlation');
        r_both_rnd(i)=corr(use_dist(:),distance.ar(:),'type','pearson','rows','pairwise');
    end
    fprintf('\n\n');
end

%%

for i=1:length(use_scalars)
   [r,p]=corr(both_distance{end}(:),distance.(use_scalars{i})(:),'type','pearson','rows','pairwise');
   fprintf('%s, r=%g p=%g\n',use_scalars{i},r,p);
end

neural_distance=struct();

neural_distance.gcamp=gcamp_distance{end};
neural_distance.rcamp=rcamp_distance{end};
neural_distance.both=both_distance{end};
neural_distance.df=diff_distance{end};

combo=[distance.ar(:) distance.height_ave(:) distance.angle(:) distance.velocity_mag(:)];
%combo=x2fx(combo,'interaction');

[b,fitinfo]=lasso(combo,both_distance{end}(:),'cv',10,'alpha',1,'standardize',false);
use_b=b(:,fitinfo.IndexMinMSE);
distance.combined=(combo*use_b)'+fitinfo.Intercept(fitinfo.IndexMinMSE);
use_distances={'ar','height_ave','angle','velocity_mag'};
use_intercept=fitinfo.Intercept(fitinfo.IndexMinMSE);

save('lasso_distance.mat','use_b','use_distances','use_intercept','use_idx');

[b_df,fitinfo_df]=lasso(combo,diff_distance{end}(:),'cv',10,'alpha',1,'standardize',false);
use_b_df=b_df(:,fitinfo_df.IndexMinMSE);
distance.combined_df=(combo*use_b_df)'+fitinfo_df.Intercept(fitinfo_df.IndexMinMSE);

%%


% shuffles

% simply shuffle the distance 1000 times, make a little histogram for each
% comparison

combos={'ar','rcamp';...
    'ar','gcamp';...
    'ar','both'};

nshuffles=1000;

rshuffles=struct();

for i=1:size(combos,1)
    for j=1:nshuffles
       scr_distance=distance.(combos{i,1});
       scr_distance=scr_distance(randperm(length(scr_distance)));
       [r,p]=corr(neural_distance.(combos{i,2})(:),scr_distance(:),'type','pearson','rows','complete');
       rshuffles.(combos{i,2}).r(j)=r;
       rshuffles.(combos{i,2}).p(j)=p;
    end
end

[ract.gcamp,p]=corr(neural_distance.gcamp(:),distance.ar(:),'type','pearson','rows','complete');
[ract.rcamp,p]=corr(neural_distance.rcamp(:),distance.ar(:),'type','pearson','rows','complete');
[ract.both,p]=corr(neural_distance.both(:),distance.ar(:),'type','pearson','rows','complete');

%%

shuffle_histogram=schfigure();
shuffle_histogram.name='shuffle_histogram';
shuffle_histogram.dims='1x4.5';
ax=[];
for i=1:size(combos,1)
    ax(i)=subplot(3,1,i);
    schfigure.stair_histogram(rshuffles.(combos{i,2}).r,[-.5:.01:.5]);
    ylims=ylim();
    hold on;
    plot(repmat(ract.(combos{i,2}),[1 2]),ylims,'r--');
    schfigure.sparsify_axis(gca);
    schfigure.outify_axis;
    set(gca,'FontSize',10);
    if i<3
        set(gca,'xtick',[]);
    end
    xlim([-.5 .5]);

end

linkaxes(ax);

%%



shuffle_histogram_pathway=schfigure();
shuffle_histogram_pathway.name='shuffle_histogram_pathway';
shuttle_histogram_pathway.dims='1.5x1.5';

both_distance=pdist(zscore([rcamp_use;gcamp_use])','correlation');
[r_both,p_both]=corr(both_distance(:),(distance.ar(:)),'type','pearson','rows','pairwise');

schfigure.stair_histogram(r_both_rnd,[.2:.0005:.5]);
hold on
ylims=ylim();
plot(repmat(r_both,[1 2]),ylims,'r--');
xlim([.2 .5]);

schfigure.sparsify_axis;
schfigure.outify_axis;
set(gca,'FontSize',10);


%%
dists=fieldnames(distance);
neural_dists=fieldnames(neural_distance);
counter=1;
stats=struct();

ncmap_points=100;

cmaps.both=[linspace(.25,1,ncmap_points)' linspace(.25,1,ncmap_points)' zeros(ncmap_points,1)]
cmaps.gcamp=[zeros(ncmap_points,1) linspace(.25,1,ncmap_points)' zeros(ncmap_points,1)];
cmaps.rcamp=[linspace(.25,1,ncmap_points)' zeros(ncmap_points,1) zeros(ncmap_points,1)];
cmaps.diff=[linspace(.25,1,ncmap_points)' zeros(ncmap_points,1) linspace(.25,1,ncmap_points)'];

combos={
    'ar','rcamp';...
    'ar','gcamp';...
    'ar','both'};

modelr=schfigure();
modelr.dims='1.4x5';
modelr.name='modelr';
nboots=1e2;
ax=[];

bootfun=@(x) regress(x(:,1),[ones(size(x(:,2))) x(:,2)]);
%bootfun=@(x) robustfit(x(:,2),x(:,1));
eval_fun=@(x,b1,b2) b1*x+b2;

for i=1:size(combos,1)
        
    ax(i)=subplot(3,1,i);
    xregress=(distance.(combos{i,1})(:));
    yregress=(neural_distance.(combos{i,2})(:));
    
    boots=bootstrp(1e2,bootfun,[yregress xregress]);
    obs_b=bootfun([yregress xregress]);

    boot_sem=std(boots);

    upper_ci=eval_fun(xregress,obs_b(2)+boot_sem(2),obs_b(1)+boot_sem(1));
    lower_ci=eval_fun(xregress,obs_b(2)-boot_sem(2),obs_b(1)-boot_sem(1));
% 
     name=sprintf('%s_%s',combos{i,1},combos{i,2});
     stats.(name)=nan(1,2);
     [stats.(name)(1) stats.(name)(2)]=corr(xregress(:),yregress(:),'type','pearson');
% 
    [~,sortidx]=sort(xregress);
    ci=[upper_ci(sortidx)';lower_ci(sortidx)'];

    %scatter(xregress,yregress,10,'filled')
    schfigure.scatter_density(xregress,yregress,[30 30],[3 3])
    schfigure.shaded_errorbar(xregress(sortidx),ci,[.5 .5 .5],'none');
     hold on;
    plot(xregress,eval_fun(xregress,obs_b(2),obs_b(1)),'k-');
    title([sprintf('r=%.02f',stats.(name)(1))]);
    %scatter(xregress,yregress,10,'filled')
    colormap(ax(i),cmaps.(combos{i,2}));

    
    
    axis tight;
    schfigure.outify_axis;
    schfigure.sparsify_axis(gca,.1);
    set(gca,'FontSize',10);
    counter=counter+1;
    
    if i<5
        set(gca,'xtick',[]);
    end
        
end

% then plot using the combined scores...


modelr(2)=schfigure;
modelr(2).dims='3x2';
modelr(2).name='modelr_combined';
ax=[];
% show the regression coefficients in one panel, then combined correlation
% in the other...
ax(1)=subplot(1,2,1);
bar(use_b);
set(gca,'XTick',[1:4],'XTickLabel',{'MoSeq','Height','Angle','Velocity'});
xtickangle(90);

box off;

ax(2)=subplot(1,2,2);

xregress=distance.combined(:);
yregress=neural_distance.both(:);

boots=bootstrp(1e2,bootfun,[yregress xregress]);
obs_b=bootfun([yregress xregress]);
sem=std(boots);

upper_ci=eval_fun(xregress,obs_b(2)+boot_sem(2),obs_b(1)+boot_sem(1));
lower_ci=eval_fun(xregress,obs_b(2)-boot_sem(2),obs_b(1)-boot_sem(1));

name=sprintf('%s_%s','combined','both');

stats.(name)=nan(1,2);
[stats.(name)(1) stats.(name)(2)]=corr(xregress(:),yregress(:),'type','pearson');

[~,sortidx]=sort(xregress);
ci=[upper_ci(sortidx)';lower_ci(sortidx)'];

%scatter(xregress,yregress,10,'filled')
schfigure.scatter_density(xregress,yregress,[30 30],[3 3])
schfigure.shaded_errorbar(xregress(sortidx),ci,[.5 .5 .5],'none');
hold on;
plot(xregress,eval_fun(xregress,obs_b(2),obs_b(1)),'k-');
title([sprintf('r=%.02f',stats.(name)(1))]);
%scatter(xregress,yregress,10,'filled')
colormap(ax(2),cmaps.both);

axis tight;
schfigure.outify_axis;
schfigure.sparsify_axis(gca,.1);
set(gca,'FontSize',10);

%schfigure.scatter_density(


phanalysis.print_stats('test.txt',stats,[],'notes','pearson r p-value');


%%

modelr(3)=schfigure;
modelr(3).dims='3x2';
modelr(3).name='modelr_both_v_df';
ax=[];
% show the regression coefficients in one panel, then combined correlation
% in the other...
ax(1)=subplot(1,2,1);
bar(use_b_df);
set(gca,'XTick',[1:4],'XTickLabel',{'MoSeq','Height','Angle','Velocity'});
title('Difference');
ylim([0 .6]);
xtickangle(90);
linkaxes(ax,'xy');
box off;

xregress=distance.combined_df(:);
yregress=neural_distance.df(:);

boots=bootstrp(1e2,bootfun,[yregress xregress]);
obs_b=bootfun([yregress xregress]);
sem=std(boots);

upper_ci=eval_fun(xregress,obs_b(2)+boot_sem(2),obs_b(1)+boot_sem(1));
lower_ci=eval_fun(xregress,obs_b(2)-boot_sem(2),obs_b(1)-boot_sem(1));

ax(2)=subplot(1,2,2);
name=sprintf('%s_%s','combined','df');

stats.(name)=nan(1,2);
[stats.(name)(1) stats.(name)(2)]=corr(xregress(:),yregress(:),'type','pearson');

[~,sortidx]=sort(xregress);
ci=[upper_ci(sortidx)';lower_ci(sortidx)'];

%scatter(xregress,yregress,10,'filled')
schfigure.scatter_density(xregress,yregress,[30 30],[3 3])
schfigure.shaded_errorbar(xregress(sortidx),ci,[.5 .5 .5],'none');
hold on;
plot(xregress,eval_fun(xregress,obs_b(2),obs_b(1)),'k-');
title([sprintf('r=%.02f',stats.(name)(1))]);
%scatter(xregress,yregress,10,'filled')
colormap(ax(2),cmaps.diff);

axis tight;
xlim([0 1.6]);

schfigure.outify_axis;
schfigure.sparsify_axis(gca,.1);
set(gca,'FontSize',10);

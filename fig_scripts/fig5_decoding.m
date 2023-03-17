%%

if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/1pimaging_dls/phanalysis_object.mat');
    phan=phanalysis_object;
end


%%
% N(cells) viz.

load('~/Desktop/phanalysis_images/decoding_results/decoding_results_1pimaging_ncells.mat')

grps={'d1','d2','both'};
boots=struct();
ci=struct();
mu=struct();
xvec=unique(performance.ncells);

for i=1:length(grps)
    boots.(grps{i})=bootstrp(1e3,@nanmean,squeeze(nanmean(performance.(grps{i}))));
    mu.(grps{i})=nanmean(squeeze(nanmean(performance.(grps{i}))));
    ci.(grps{i})=[std(boots.(grps{i}))*2.58+mu.(grps{i});-std(boots.(grps{i}))*2.58+mu.(grps{i})];
    sem.(grps{i})=std(boots.(grps{i}));
    %ci.(grps{i})=prctile(boots.(grps{i}),[.5 99.5]);
end


decoding_ncells=schfigure();
decoding_ncells.name=sprintf('ncells_decoding_performance_mean_pseudo');
decoding_ncells.dims='2x4';
decoding_ncells.formats='png,fig,pdf';

subplot(2,1,1);

colors=[1 0 0;0 1 0;1 1 0];

for i=1:length(grps)
   schfigure.shaded_errorbar(xvec,ci.(grps{i}),colors(i,:),'none');
   hold on;
   plot(xvec,mu.(grps{i}),'k.-');
end
plot(xvec,squeeze(prctile(nanmedian(performance.rnd,2),95)),'k--');

xlim([xvec(1) 600]);
ylim([0 .25]);
subplot(2,1,2);
for i=1:length(grps)
   schfigure.shaded_errorbar(xvec,ci.(grps{i}),colors(i,:),'none');
   hold on;
   plot(xvec,mu.(grps{i}),'k.-');
end
plot(xvec,squeeze(prctile(nanmedian(performance.rnd,2),95)),'k--');

xlim([xvec(1) 40]);
ylim([0 .15]);

schfigure.sparsify_axis;
schfigure.outify_axis;



%%
% hierarchy
% 

load('~/Desktop/phanalysis_images/decoding_results/decoding_results_1pimaging_moseq_hierarchy.mat')


interp_factor=1;

% rem the trivial cases
use_points=[1 4 8 11 14 18];
xvec=1:length(unique(performance.levels));
xvec=xvec(use_points);

plt_performance=struct();

plt_performance.d1=performance.d1(:,:,use_points);
plt_performance.d2=performance.d2(:,:,use_points);
plt_performance.both=performance.both(:,:,use_points);
plt_performance.rnd=performance.rnd(:,:,use_points);
plt_performance.levels=performance.levels(use_points);


torem=find(all(squeeze(all(plt_performance.d2==1))));

colors=[1 0 0;0 1 0;1 1 0];

plt_performance.d1(:,:,torem)=[];
plt_performance.d2(:,:,torem)=[];
plt_performance.both(:,:,torem)=[];
plt_performance.rnd(:,:,torem)=[];
plt_performance.levels(torem)=[];


for i=1:length(grps)
    boots.(grps{i})=bootstrp(1e3,@nanmean,squeeze(nanmean(plt_performance.(grps{i}))));
    mu.(grps{i})=nanmean(squeeze(nanmean(plt_performance.(grps{i}))));
    ci.(grps{i})=[std(boots.(grps{i}))*2.58+mu.(grps{i});-std(boots.(grps{i}))*2.58+mu.(grps{i})];
    %ci.(grps{i})=prctile(boots.(grps{i}),[.5 99.5]);
    %ci.(grps{i})=prctile(squeeze(nanmean(plt_performance.(grps{i}))),[2.5 97.5]);
end

decoding_ncells_hierarchy=schfigure();
decoding_ncells_hierarchy.name=sprintf('ncells_decoding_performance_hierarchy');
decoding_ncells_hierarchy.dims='2x3';

for i=1:length(grps)
   schfigure.shaded_errorbar(xvec,ci.(grps{i}),colors(i,:),'none');
   hold on;
   plot(xvec,mu.(grps{i}),'k.-');
end

plot(xvec,squeeze(prctile(nanmedian(plt_performance.rnd,2),95)),'k--');
xlim([1 xvec(end)]);
ylim([0 .9]);
set(gca,'xdir','rev')
schfigure.sparsify_axis;
schfigure.outify_axis;

%%


dendro_decode=schfigure();
dendro_decode.name='inscopix_decoding_hierarchy_dendrogram';
dendro_decode.dims='2x2';

Z=linkage(squareform(phan.distance.inter.ar(1:phan.options.syllable_cutoff,1:phan.options.syllable_cutoff),'tovector'),'complete');

dendrogram(Z,0);
hold on;
ylim([0 2]);
xlims=xlim();
uniq_levels=unique(performance.levels);
levels=uniq_levels(use_points);
for i=1:length(levels)
    plot(xlims,repmat(levels(i),[1 2]),'k-');
end
schfigure.outify_axis;
schfigure.sparsify_axis;

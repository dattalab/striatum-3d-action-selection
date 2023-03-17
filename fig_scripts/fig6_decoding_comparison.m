%%

if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/1pimaging_dls/phanalysis_object.mat');
    phan=phanalysis_object;
end


%%
% separate
load('~/Desktop/phanalysis_images/decoding_results/decoding_results_1pimaging_ncells_zoom.mat')

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
%%
% simultaneous
load('~/Desktop/phanalysis_images/decoding_results/decoding_results_1pimaging_twocolor_pseudopop.mat')

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

%%
% within animal

load('~/Desktop/phanalysis_images/decoding_results/decoding_results_1pimaging_twocolor_withinanimal.mat')


decoding_ncells=schfigure();
decoding_ncells.name=sprintf('ncells_decoding_performance_mean_withinanimal');
decoding_ncells.dims='2x4';
decoding_ncells.formats='png,fig,pdf';


grps={'within'};
use_mice=[1];
mu=[];
ci=[];

for i=1:length(use_mice)
   boots=bootstrp(1e3,@nanmean,squeeze(nanmean(performance.within(:,:,:,use_mice(i))))); 
   mu(:,i)=nanmean(squeeze(nanmean(performance.within(:,:,:,use_mice(i)))));
   ci(:,:,i)=[std(boots)*2.58+mu(:,i)';-std(boots)*2.58+mu(:,i)'];   
end

%xvec=1:length(unique(performance.levels));
xvec=unique(performance.ncells);

subplot(2,1,1);

colors=[1 1 0];
for i=1:length(use_mice)
   schfigure.shaded_errorbar(xvec,ci(:,:,i),colors(i,:),'none');
   hold on;
   plot(xvec,mu(:,i),'k.-');
end

grps={'within'};
use_mice=[1];
mu=[];
ci=[];

for i=1:length(use_mice)
   boots=bootstrp(1e3,@nanmean,squeeze(nanmean(old_performance.within(:,:,:,use_mice(i))))); 
   mu(:,i)=nanmean(squeeze(nanmean(old_performance.within(:,:,:,use_mice(i)))));
   ci(:,:,i)=[std(boots)*2.58+mu(:,i)';-std(boots)*2.58+mu(:,i)'];   
end

%xvec=1:length(unique(performance.levels));
xvec=unique(old_performance.ncells);

subplot(2,1,1);

colors=[1 .5 0];
for i=1:length(use_mice)
   schfigure.shaded_errorbar(xvec,ci(:,:,i),colors(i,:),'none');
   hold on;
   plot(xvec,mu(:,i),'k.-');
end
plot(xvec,squeeze(prctile(median(performance.rnd,2),95)),'k--');

xlim([xvec(1) 40]);
ylim([0 .15]);

schfigure.sparsify_axis;
schfigure.outify_axis;

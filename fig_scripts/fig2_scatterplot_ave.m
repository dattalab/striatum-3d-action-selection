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

%%

use_peaks=false; % use the average, not the peak value
win=[]; % don't simply take a window around onset, use the actual syllable duration 
duration_win=[.05 .05]; % takes onset-duration_win(1) until offset-duration(2)
peaks_rnd=extract_syllable_onsets(phan,model_starts,'use_window',win,'use_id','','randomize',true,'use_peaks',use_peaks,'duration_window',duration_win);
clear peaks_single;
peaks_single(1)=extract_syllable_onsets(phan,model_starts,'use_window',win,'use_id','1538','use_peaks',use_peaks,'duration_window',duration_win);
peaks_single(2)=extract_syllable_onsets(phan,model_starts,'use_window',win,'use_id','19842','use_peaks',use_peaks,'duration_window',duration_win);
peaks_single(3)=extract_syllable_onsets(phan,model_starts,'use_window',win,'use_id','1532','use_peaks',use_peaks,'duration_window',duration_win);
peaks_all=extract_syllable_onsets(phan,model_starts,'use_window',win,'use_id','','use_peaks',use_peaks,'duration_window',duration_win);

%%
nplots=2+length(peaks_single);

% get the observations
radius=.1;
cutoff=phan.options.syllable_cutoff;

mu_rcamp=cellfun(@nanmean,peaks_all.rcamp(1:cutoff));
rcamp_mu=mean(mu_rcamp);
rcamp_sig=std(mu_rcamp);
mu_gcamp=cellfun(@nanmean,peaks_all.gcamp(1:cutoff));
gcamp_mu=mean(mu_gcamp);
gcamp_sig=std(mu_gcamp);

% and now bootstrap the se's

se_gcamp=nan(1,cutoff);
se_rcamp=nan(1,cutoff);
nboots=100;
upd=kinect_extract.proc_timer(cutoff);

for i=1:cutoff
    boot_samples=bootstrp(nboots,@nanmean,(peaks_all.gcamp{i}-gcamp_mu)./gcamp_sig);
    se_gcamp(i)=std(boot_samples);
    boot_samples=bootstrp(nboots,@nanmean,(peaks_all.rcamp{i}-rcamp_mu)./rcamp_sig);
    se_rcamp(i)=std(boot_samples);
    upd(i);
end

plot_rcamp=zscore(mu_rcamp);
plot_gcamp=zscore(mu_gcamp);

use_colors=jet(cutoff);

[~,sort_idx]=sort(plot_rcamp(:),'descend');
%use_colors=use_colors(sort_idx,:);

errorbar_rcamp=[plot_rcamp+se_rcamp;plot_rcamp-se_rcamp];
errorbar_gcamp=[plot_gcamp+se_gcamp;plot_gcamp-se_gcamp];

scatter_fig(1)=schfigure([],false);
scatter_fig(1).name='d1d2_scatterplot_dff0_pooled';
scatter_fig(1).dims='10x8';
subplot(1,nplots,1);

hold on;
plot([0 0],[-4 4],'k-');
plot([-4 4],[0 0],'k-');
plot(errorbar_rcamp,ones(size(errorbar_rcamp)).*plot_gcamp,'k-','color',[.5 .5 .5])
plot(ones(size(errorbar_rcamp)).*plot_rcamp,errorbar_gcamp,'k-','color',[.5 .5 .5])
for i=1:length(plot_rcamp)
    h(i)=rectangle('position',[ plot_rcamp(i)-radius plot_gcamp(i)-radius radius*2 radius*2],'curvature',1,'facecolor',use_colors(i==sort_idx,:),'edgecolor','none');
end
axis([-4 4 -4 4])
axis square;
schfigure.sparsify_axis([],[],[],[-4 0 4],[-4 0 4]);
schfigure.outify_axis;
[r_onset,p_onset]=corr(plot_rcamp(:),plot_gcamp(:),'rows','pairwise','type','pearson');
title([sprintf('r=%.02g',r_onset)]);
set(gca,'FontSize',10)
xlabel('D1 activity (z)');
ylabel('D2 activity (z)');

%%

for ii=1:length(peaks_single)
    mu_rcamp=cellfun(@nanmean,peaks_single(ii).rcamp(1:cutoff));
    rcamp_mu=mean(mu_rcamp);
    rcamp_sig=std(mu_rcamp);
    mu_gcamp=cellfun(@nanmean,peaks_single(ii).gcamp(1:cutoff));
    gcamp_mu=mean(mu_gcamp);
    gcamp_sig=std(mu_gcamp);

    % and now bootstrap the se's

    se_gcamp=nan(1,cutoff);
    se_rcamp=nan(1,cutoff);
    nboots=100;
    upd=kinect_extract.proc_timer(cutoff);

    for i=1:cutoff
        boot_samples=bootstrp(nboots,@nanmean,(peaks_single(ii).gcamp{i}-gcamp_mu)./gcamp_sig);
        se_gcamp(i)=std(boot_samples);
        boot_samples=bootstrp(nboots,@nanmean,(peaks_single(ii).rcamp{i}-rcamp_mu)./rcamp_sig);
        se_rcamp(i)=std(boot_samples);
        upd(i);
    end

    plot_rcamp=zscore(mu_rcamp);
    plot_gcamp=zscore(mu_gcamp);
    errorbar_rcamp=[plot_rcamp+se_rcamp;plot_rcamp-se_rcamp];
    errorbar_gcamp=[plot_gcamp+se_gcamp;plot_gcamp-se_gcamp];

    subplot(1,nplots,1+ii);

    hold on;
    plot([0 0],[-4 4],'k-');
    plot([-4 4],[0 0],'k-');
    plot(errorbar_rcamp,ones(size(errorbar_rcamp)).*plot_gcamp,'k-','color',[.5 .5 .5])
    plot(ones(size(errorbar_rcamp)).*plot_rcamp,errorbar_gcamp,'k-','color',[.5 .5 .5])
    for i=1:length(plot_rcamp)
        h(i)=rectangle('position',[ plot_rcamp(i)-radius plot_gcamp(i)-radius radius*2 radius*2],'curvature',[1 1],'facecolor',use_colors(i==sort_idx,:),'edgecolor','none');
    end
    
    axis([-4 4 -4 4])
    axis square;

    schfigure.sparsify_axis([],[],[],[-4 0 4],[-4 0 4]);
    schfigure.outify_axis;
     set(gca,'FontSize',10)
%     xlabel('D1 activity (z)');
%     ylabel('D2 activity (z)');
end

mu_rcamp=cellfun(@nanmean,peaks_rnd.rcamp(1:cutoff));
rcamp_mu=mean(mu_rcamp);
rcamp_sig=std(mu_rcamp);
mu_gcamp=cellfun(@nanmean,peaks_rnd.gcamp(1:cutoff));
gcamp_mu=mean(mu_gcamp);
gcamp_sig=std(mu_gcamp);

% and now bootstrap the se's

se_gcamp=nan(1,cutoff);
se_rcamp=nan(1,cutoff);
nboots=100;
upd=kinect_extract.proc_timer(cutoff);

for i=1:cutoff
    boot_samples=bootstrp(nboots,@nanmean,(peaks_rnd.gcamp{i}-gcamp_mu)./gcamp_sig);
    se_gcamp(i)=std(boot_samples);
    boot_samples=bootstrp(nboots,@nanmean,(peaks_rnd.rcamp{i}-rcamp_mu)./rcamp_sig);
    se_rcamp(i)=std(boot_samples);
    upd(i);
end

plot_rcamp=zscore(mu_rcamp);
plot_gcamp=zscore(mu_gcamp);
errorbar_rcamp=[plot_rcamp+se_rcamp;plot_rcamp-se_rcamp];
errorbar_gcamp=[plot_gcamp+se_gcamp;plot_gcamp-se_gcamp];

subplot(1,nplots,nplots);

hold on;
plot([0 0],[-4 4],'k-');
plot([-4 4],[0 0],'k-');
plot(errorbar_rcamp,ones(size(errorbar_rcamp)).*plot_gcamp,'k-','color',[.5 .5 .5])
plot(ones(size(errorbar_rcamp)).*plot_rcamp,errorbar_gcamp,'k-','color',[.5 .5 .5])
for i=1:length(plot_rcamp)
    h(i)=rectangle('position',[ plot_rcamp(i)-radius plot_gcamp(i)-radius radius*2 radius*2],'curvature',[1 1],'facecolor',use_colors(i,:),'edgecolor','none');
end
axis([-4 4 -4 4])
axis square;

schfigure.sparsify_axis([],[],[],[-4 0 4],[-4 0 4]);
schfigure.outify_axis;
set(gca,'FontSize',10)
% xlabel('D1 activity (z)');
% ylabel('D2 activity (z)');

%%

width=10;
height=10;
spacer=1;

rows=length(plot_rcamp);
tot_height=(height+spacer)*rows;
spacer_color=[0 0 0];

bar_image=schfigure;
bar_image.name='d1d2_scatterplot_dff0_bar_im';
bar_image.dims='1.5x5';
bar_image.formats='pdf,png,fig';

imagesc(linspace(0,1,size(use_colors,1))');
colormap(use_colors);
hold on;
plot(repmat([.5 1.5],[size(use_colors,1) 1])',repmat([1:size(use_colors,1)]'-.5,[1 2])')
set(gca,'xtick',[],'ytick',[])


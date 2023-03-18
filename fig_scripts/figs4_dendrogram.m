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
    phan.compute_scalars_summary;
end

%%
% grab the model distance, form a linkage, get the optimal leaf ordering
% and you know the rest...

cutoff=phan.options.syllable_cutoff;
sz='3x8';
dendro_lims=[0 2];

linkage_type='complete';
usemat=squareform(phan.distance.inter.ar(1:cutoff,1:cutoff),'tovector');
z=linkage(usemat,linkage_type);
crit='group';
outperm=optimalleaforder(z,usemat,'criteria',crit,'transformation','linear');
perm_colors=colormap(sprintf('parula(%i)',length(outperm)+3));



%%

dendro=schfigure([],false);
dendro.dims=sz;
dendro.name='model_dendrogram_waveforms_randsample';

dendro_axis=subplot(cutoff,2,1:2:cutoff*2);
h=dendrogram(z,0,'reorder',outperm);
ylim([dendro_lims]);
schfigure.sparsify_axis([],.1,'y');
schfigure.outify_axis([],[.01 .01]);
xlabel('Syllable ID');
ylabel('Distance');
view([270 270]);

spacing=1;
zplot_ax=[];

dendro_pos=get(dendro_axis,'position');
left_edge=dendro_pos(1)+dendro_pos(3)+.05;
top=.92;
zwidth=.2;
zheight=.02;
zspacing=.8/phan.options.syllable_cutoff;
bootfun=@(x) nanmean(x);
rng default;

randsamples=1000;

for i=1:length(outperm)
    
    ex=outperm(i);
    
    % grab a small number of trials at random
    
    gcamp_stitch=zscore(cat(2,model_starts.gcamp(ex,:).wins));
    rcamp_stitch=zscore(cat(2,model_starts.rcamp(ex,:).wins));
    
    ngcamp=size(gcamp_stitch,2);
    nrcamp=size(rcamp_stitch,2);
    
    gcamp_pool=randperm(ngcamp);
    rcamp_pool=randperm(nrcamp);
    
    gcamp_stitch=gcamp_stitch(:,gcamp_pool(1:min(ngcamp,randsamples)));
    rcamp_stitch=rcamp_stitch(:,rcamp_pool(1:min(nrcamp,randsamples)));

    
    
    tvec=floor(size(gcamp_stitch,1)/2);
    tvec=(-tvec:tvec)/30;
   
    gcamp_mu=bootfun(gcamp_stitch');
    rcamp_mu=bootfun(rcamp_stitch');
    axes('position',[left_edge top-(i*zspacing) zwidth zheight]);
    
    
    hold on;
    plot(tvec,gcamp_mu,'g-');
    plot(tvec,rcamp_mu,'r-');
    ylims=ylim();
    h=plot([-2 -2],[ylims(1) ylims(1)+.1],'k-');
    h.Clipping='off';
    h=plot([-2 -1.5],[ylims(1) ylims(1)],'k-');
    h.Clipping='off';
    ylim([ylims]);
    
    xlim([-2 3]);
    axis off;
    plot([0 0],get(gca,'ylim'),'k-','color',[.5 .5 .5]);

    
end



%%

dendro(2)=schfigure([],false);
dendro(2).name=sprintf('model_dendrogram_waveforms_pca');
dendro(2).dims=sz;
dendro_axis=subplot(cutoff,2,1:2:cutoff*2);
h=dendrogram(z,0,'reorder',outperm);
ylim([dendro_lims]);
schfigure.sparsify_axis([],.1,'y');
schfigure.outify_axis([],[.01 .01]);
xlabel('Syllable ID');
ylabel('Distance');
view([270 270]);

spacing=1;
zplot_ax=[];

dendro_pos=get(dendro_axis,'position');
left_edge=dendro_pos(1)+dendro_pos(3)+.05;
top=.92;
zwidth=.2;
zheight=.02;
zspacing=.8/phan.options.syllable_cutoff;
bootfun=@(x) nanmean(x);

for i=1:length(outperm)
    
    ex=outperm(i);
    
    trajectory=phan.get_ar_trajectory(ex);
     
    axes('position',[left_edge top-(i*zspacing) zwidth zheight]);
    %trace_figs(i).shaded_errorbar(tvec,gcamp_ci,[0 1 0],'none');
    hold on;
    plot(trajectory(1:20,1),trajectory(1:20,2));
    %axis([-2 2 -2 2]);
    axis off;
    
    %
end

%%

dendro(3)=schfigure([],false);
dendro(3).dims=sz;
dendro(3).name=sprintf('model_dendrogram_waveforms');

dendro_axis=subplot(cutoff,2,1:2:cutoff*2);
h=dendrogram(z,0,'reorder',outperm);
ylim([dendro_lims]);
schfigure.sparsify_axis([],.1,'y');
schfigure.outify_axis([],[.01 .01]);
xlabel('Syllable ID');
ylabel('Distance');
view([270 270]);

spacing=1;
zplot_ax=[];

dendro_pos=get(dendro_axis,'position');
left_edge=dendro_pos(1)+dendro_pos(3)+.05;
top=.92;
zwidth=.2;
zheight=.02;
zspacing=.8/phan.options.syllable_cutoff;
bootfun=@(x) nanmean(x);
rng default;
nshuffles=50;
randsamples=250;

for i=1:length(outperm)
    
    ex=outperm(i);
    
    % grab a small number of trials at random
    
    gcamp_stitch=zscore(cat(2,model_starts.gcamp(ex,:).wins));
    rcamp_stitch=zscore(cat(2,model_starts.rcamp(ex,:).wins));
    
    gcamp_shuffle=phanalysis.shuffle_statistic(@nanmean,gcamp_stitch',nshuffles,true)';
    rcamp_shuffle=phanalysis.shuffle_statistic(@nanmean,rcamp_stitch',nshuffles,true)';
    
    zgcamp=@(x) (x-max(nanmean(gcamp_shuffle)))./max(nanstd(gcamp_shuffle));
    zrcamp=@(x) (x-max(nanmean(rcamp_shuffle)))./max(nanstd(rcamp_shuffle));
        
    tvec=floor(size(gcamp_stitch,1)/2);
    tvec=(-tvec:tvec)/30;
    
    gcamp_mu=zgcamp(bootfun(gcamp_stitch'));
    rcamp_mu=zrcamp(bootfun(rcamp_stitch'));
    axes('position',[left_edge top-(i*zspacing) zwidth zheight]);
    
    
    hold on;
    plot(tvec,gcamp_mu,'g-');
    plot(tvec,rcamp_mu,'r-');
    ylims=ylim();
    h=plot([-2 -2],[ylims(1) ylims(1)+1],'k-');
    h.Clipping='off';
    h=plot([-2 -1.5],[ylims(1) ylims(1)],'k-');
    h.Clipping='off';
    ylim([ylims]);
    
    xlim([-2 3]);
    axis off;
    plot([0 0],get(gca,'ylim'),'k-','color',[.5 .5 .5]);

end

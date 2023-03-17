%%
% NOTE: this script must be run in the directory where decoding results
% were saved
%
% decoding_results_photometry/20180317T013436
% 


if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/photometry_dls/phanalysis_object.mat');
    phan=phanalysis_object;
end

load('~/Desktop/phanalysis_images/decoding_results/decoding_results_photometry_moseq_hierarchy.mat')

%%

plot_fields={'all','gcamp','rcamp'};
colors=[[.75 .75 0];...
    [0 .75 0];...
    [.75 0 0]]
extensions={'_w','_dt_w','_dt_w_combined'};
% 


clear fig;
max_cut=13;

for j=1:length(extensions)
    
    fig(j)=schfigure();
    fig(j).name=sprintf('photometry_decoding_%s',extensions{j});
    fig(j).formats='pdf,png,fig';
    fig(j).dims='4x2';
    
    subplot(1,2,1);
        
    for i=1:length(plot_fields)
        
        use_data=performance.([plot_fields{i} extensions{j}]);
        use_data_rnd=performance_rnd.([plot_fields{i} extensions{j}]);
        use_idx=1:size(use_data,1);
        ign=all(use_data==1,2);
        use_idx=use_idx(~ign);
        use_idx=1:min(max_cut,length(use_idx));
        ci=squeeze(mean(prctile(use_data_rnd(use_idx,:,:),[50],3),2));

        plot(use_idx,mean(use_data(use_idx,:),2),'k.-','color',colors(i,:),'markersize',7);        
        hold on;
%         
        if i==1
            ci=squeeze(mean(prctile(use_data_rnd(use_idx,:,:),[2.5 97.5],3),2))';
            schfigure.shaded_errorbar(use_idx,ci);    
        end

    end      
    
    xlim([1 max(use_idx)])
    
    set(gca,'xdir','reverse');
    title(['sig' regexprep(extensions{j},'_',' ')])

    schfigure.outify_axis;
    schfigure.sparsify_axis(gca,[],'xy',[],[]);

       
    set(gca,'xdir','reverse');
    %title(['sig' regexprep(extensions{j},'_',' ')])
    ylim([0 .3 ]);
    schfigure.outify_axis;
    schfigure.sparsify_axis(gca,[],'xy',[],[]);
    
    
    
    subplot(1,2,2);
    
    for i=2:length(plot_fields)
        
        use_data=performance.([plot_fields{i} extensions{j}]);
        ref_data=performance.([plot_fields{1} extensions{j}]);
        
        use_idx=1:size(use_data,1);
        
        ign=all(use_data==1,2);
        use_idx=use_idx(~ign);
                use_idx=1:min(max_cut,length(use_idx));

        
       plot(log2(mean(ref_data(use_idx,:),2)./mean(use_data(use_idx,:),2)),'k.-','color',colors(i,:),'markersize',7); 
       hold on;
    end
    
    plot(1:size(performance.all_w,1),zeros(1,size(performance.all_w,1)),'k--');
    
    xlim([1 max(use_idx)])
    ylim([-.5 .5]);
    
    ylabel('Log2-fold performance change');
    xlabel('Hierarchy cut');
    set(gca,'xdir','reverse','FontSize',8);

    schfigure.outify_axis;
    schfigure.sparsify_axis(gca,[],'xy',[],[-.5 0 .5]);

end

%%

% print out a summary for performnace

print_field='all_dt_w_combined';

nlevels=size(performance.(print_field),1);
nfolds=size(performance.(print_field),2);
nrands=size(performance_rnd.(print_field),3);
labels=cat(2,performance_meta.all_dt_w_combined(:,1).clust_map);
nclust=nan(1,size(labels,2));

for i=1:size(labels,2)
    nclust(i)=length(unique(labels(:,i)));
end

perf=mean(performance.(print_field),2);
boot_samples=bootstrp(1e3,@mean,performance.(print_field)');
boot_sem=std(boot_samples);

chance=squeeze(mean(performance_rnd.(print_field),2));
chance_mu=nan(size(chance,1),1);
chance_sem=nan(size(chance,1),1);

for i=1:size(chance,1)
    chance_mu(i)=mean(chance(i,:));
    boot_samples=bootstrp(1e3,@mean,chance(i,:));
    chance_sem(i)=std(boot_samples);
end

for i=1:nlevels
   fprintf('Cut %i, nclusts %i, perf %g (sem %g), chance %g (sem %g)\n',i,nclust(i),perf(i)*1e2,boot_sem(i)*1e2,chance_mu(i)*1e2,chance_sem(i)*1e2);
end

%%


linkage_type='complete';
usemat=squareform(phan.distance.inter.ar(1:cutoff,1:cutoff),'tovector');
z=linkage(usemat,linkage_type);
crit='group';
outperm=optimalleaforder(z,usemat,'criteria',crit,'transformation','linear');

levels=unique([performance_meta(:,1).all_dt_w.level]);


dendro_decode=schfigure();
dendro_decode.name='photometry_decoding_dendrogram';
dendro_decode.dims='2x2';

dendrogram(z,0,'reorder',outperm);
hold on;
ylim([0 2]);
xlims=xlim();
levels_limit=16;
for i=1:4:levels_limit
    plot(xlims,repmat(levels(i),[1 2]),'k-');
end
schfigure.outify_axis;
schfigure.sparsify_axis;
set(gca,'xtick',[],'xdir','rev');



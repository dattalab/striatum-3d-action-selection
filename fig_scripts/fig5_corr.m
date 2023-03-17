%%

if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/1pimaging_dls/phanalysis_object.mat');
    phan=phanalysis_object;
end


%%


cut=phan.options.syllable_cutoff;
train_cut=15;
grps={'d1','a2a','wt'};
shift=0;
phan.set_option('scalar_shift',shift);
phan.compute_scalars_correlation;

cmap=[linspace(0,1,100)' linspace(0,1,100)' zeros(100,1)];
mouse_grps=phan.get_genos;
mouse_grps(strcmp(mouse_grps,'d1nlstdtom'))={'wt'};

nrands=1000;
pool_size=600;
r=nan(nrands,length(grps));
upd=kinect_extract.proc_timer(nrands);

for ii=1:nrands
    
    for i=1:length(grps)
        
        beh_dist=(phan.distance.inter.ar(1:cut,1:cut));
        beh_dist=squareform(beh_dist,'tovector');
        tmp_mice=find(contains(mouse_grps,grps{i}));
        templates_combined=[];
        
        for j=1:length(tmp_mice)
            
            
            use_data=phanalysis.nanzscore(phan.stats.corr_imaging(tmp_mice(j)).data);
            nrois=size(use_data,2);
            
            use_labels=[phan.stats.corr_scalars(tmp_mice(j)).model_labels];
            [nsamples,nrois]=size(use_data);
            templates=nan(nrois,cut);
            
            for k=1:cut
                if sum(use_labels==k)>train_cut
                    templates(:,k)=nanmean(use_data(use_labels==k,:));
                end
            end
            
            templates_combined=[templates_combined;templates];
            
        end
        
        nrois=size(templates_combined,1);
        rndpool=randperm(nrois);
        
        neural_dist_all=pdist(phanalysis.nanzscore(templates_combined(rndpool(1:pool_size),:)'),'correlation');
        beh_dist_all=beh_dist(:);
        nans=isnan(beh_dist_all(:))|isnan(neural_dist_all(:));
        r(ii,i)=corr(beh_dist_all(:),neural_dist_all(:),'type','pearson','rows','pairwise');
        
        
    end
    
    upd(ii);
    
end

%%

grps={'d1','a2a'};
templates_combined=struct();
r_combined=nan(nrands,1);

for ii=1:nrands
    
    for i=1:length(grps)
        
        beh_dist=(phan.distance.inter.ar(1:cut,1:cut));
        beh_dist=squareform(beh_dist,'tovector');
        tmp_mice=find(contains(mouse_grps,grps{i}));
        templates_combined.(grps{i})=[];
        
        for j=1:length(tmp_mice)
                                    
            use_data=phanalysis.nanzscore(phan.stats.corr_imaging(tmp_mice(j)).data);
            nrois=size(use_data,2);
            
            use_labels=[phan.stats.corr_scalars(tmp_mice(j)).model_labels];
            [nsamples,nrois]=size(use_data);
            templates=nan(nrois,cut);
            
            for k=1:cut
                if sum(use_labels==k)>train_cut
                    templates(:,k)=nanmean(use_data(use_labels==k,:));
                end
            end
            
            templates_combined.(grps{i})=[templates_combined.(grps{i});templates];
            
        end                
    end
    
    nrois_d1=size(templates_combined.d1,1);
    nrois_d2=size(templates_combined.a2a,1);
    
    rndpool_d1=randperm(nrois_d1);
    rndpool_d2=randperm(nrois_d2);
    use_pool_size=fix(pool_size/2);
    
    dist_data=phanalysis.nanzscore([(templates_combined.d1(rndpool_d1(1:use_pool_size),:));...
        (templates_combined.a2a(rndpool_d2(1:use_pool_size),:))]')';
    
    neural_dist_all=pdist(dist_data','correlation');
    beh_dist_all=beh_dist(:);
    nans=isnan(beh_dist_all(:))|isnan(neural_dist_all(:));
    r_combined(ii)=corr(beh_dist_all(:),neural_dist_all(:),'type','pearson','rows','pairwise');
    
end

%%

pathway_comparison=schfigure();
pathway_comparison.name='ca_template_corr_comparison';
pathway_comparison.dims='3x2';

schfigure.stair_histogram(r(:,1),[0:.005:1],'normalize',false,'k-','color','r');
hold on;
schfigure.stair_histogram(r(:,2),[0:.005:1],'normalize',false,'k-','color','g');
schfigure.stair_histogram(r(:,3),[0:.005:1],'normalize',false,'k-','color',[1 .75 0]);
xlim([.65 .8]);
schfigure.outify_axis;
schfigure.sparsify_axis;
xlabel('Neural-->behavioral dist corr. (r)');
ylabel('Count');

%%

pathway_comparison_combined=schfigure();
pathway_comparison_combined.name='ca_template_corr_comparison_combined';
pathway_comparison_combined.dims='3x2';

schfigure.stair_histogram(r(:,1),[0:.005:1],'normalize',false,'k-','color','r');
hold on;
schfigure.stair_histogram(r(:,2),[0:.005:1],'normalize',false,'k-','color','g');
schfigure.stair_histogram(r_combined,[0:.005:1],'normalize',false,'k-','color',[1 .75 0]);
xlim([.65 .8]);
schfigure.outify_axis;
schfigure.sparsify_axis;
xlabel('Neural-->behavioral dist corr. (r)');
ylabel('Count');

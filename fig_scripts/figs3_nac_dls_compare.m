%%
%

% load in the changepoint averages from both NAC and DLS for comparison


nac=load('~/Desktop/phanalysis_images/changepoints_stats_nac.mat');
dls=load('~/Desktop/phanalysis_images/changepoints_stats_dls.mat');

% now normalize each by its respective noise level

%%

shufflez=@(x,y) bsxfun(@rdivide,bsxfun(@minus,x,nanmean(y)),nanstd(y));

chk_fields={'wins','wins_dt'};
opts=statset('UseParallel',true);
nac_z=struct();
dls_z=struct();

for i=1:length(chk_fields)
    nac_z.(chk_fields{i}).gcamp=shufflez(nac.rp_cat.(chk_fields{i}).gcamp_mu,nac.rp_cat.(chk_fields{i}).gcamp_shuffle);
    nac_z.(chk_fields{i}).rcamp=shufflez(nac.rp_cat.(chk_fields{i}).rcamp_mu,nac.rp_cat.(chk_fields{i}).rcamp_shuffle);
    dls_z.(chk_fields{i}).gcamp=shufflez(dls.rp_cat.(chk_fields{i}).gcamp_mu,dls.rp_cat.(chk_fields{i}).gcamp_shuffle);
    dls_z.(chk_fields{i}).rcamp=shufflez(dls.rp_cat.(chk_fields{i}).rcamp_mu,dls.rp_cat.(chk_fields{i}).rcamp_shuffle);
end

nboots=1e3;
use_idx=41:101;
plt_mu=struct();
chk_fields={'wins'};
all_shuffles=[];

for i=1:length(chk_fields)

    boot_rcamp_nac=bootstrp(nboots,@nanmean,nac.rp_cat.(chk_fields{i}).rcamp,'options',opts);
    boot_gcamp_nac=bootstrp(nboots,@nanmean,nac.rp_cat.(chk_fields{i}).gcamp,'options',opts);
    boot_rcamp_dls=bootstrp(nboots,@nanmean,dls.rp_cat.(chk_fields{i}).rcamp,'options',opts);
    boot_gcamp_dls=bootstrp(nboots,@nanmean,dls.rp_cat.(chk_fields{i}).gcamp,'options',opts);

    boot_rcamp_nac=shufflez(boot_rcamp_nac,nac.rp_cat.(chk_fields{i}).rcamp_shuffle);
    boot_gcamp_nac=shufflez(boot_gcamp_nac,nac.rp_cat.(chk_fields{i}).gcamp_shuffle);
    boot_rcamp_dls=shufflez(boot_rcamp_dls,dls.rp_cat.(chk_fields{i}).rcamp_shuffle);
    boot_gcamp_dls=shufflez(boot_gcamp_dls,dls.rp_cat.(chk_fields{i}).gcamp_shuffle);

    plt_mu.(chk_fields{i}).gcamp_nac=sqrt(nanmean(boot_gcamp_nac(:,use_idx)'.^2));
    plt_mu.(chk_fields{i}).rcamp_nac=sqrt(nanmean(boot_rcamp_nac(:,use_idx)'.^2));
    plt_mu.(chk_fields{i}).gcamp_dls=sqrt(nanmean(boot_gcamp_dls(:,use_idx)'.^2));
    plt_mu.(chk_fields{i}).rcamp_dls=sqrt(nanmean(boot_rcamp_dls(:,use_idx)'.^2));
    
    shuffle_rcamp_dls=shufflez(dls.rp_cat.(chk_fields{i}).rcamp_shuffle,dls.rp_cat.(chk_fields{i}).rcamp_shuffle);
    shuffle_gcamp_dls=shufflez(dls.rp_cat.(chk_fields{i}).gcamp_shuffle,dls.rp_cat.(chk_fields{i}).gcamp_shuffle);        
    shuffle_rcamp_nac=shufflez(nac.rp_cat.(chk_fields{i}).rcamp_shuffle,nac.rp_cat.(chk_fields{i}).rcamp_shuffle);
    shuffle_gcamp_nac=shufflez(nac.rp_cat.(chk_fields{i}).gcamp_shuffle,nac.rp_cat.(chk_fields{i}).gcamp_shuffle);

    all_shuffles=[sqrt(nanmean(shuffle_rcamp_dls(:,use_idx)'.^2)) ...
        sqrt(nanmean(shuffle_gcamp_dls(:,use_idx)'.^2)) ...
        sqrt(nanmean(shuffle_rcamp_nac(:,use_idx)'.^2)) ...
        sqrt(nanmean(shuffle_gcamp_nac(:,use_idx)'.^2))];

end


% make a dotted line with the p.01 cutoff
%%


nac_dls_fig=schfigure();
nac_dls_fig.name=sprintf('nac_dls_violin');
nac_dls_fig.dims='1.5x3.5';
cutoff=prctile(all_shuffles,100-1e-3);
area([-2 6],[cutoff cutoff],'facecolor',[.75 .75 .75],'edgecolor','none');
hold on;
tmp=schfigure.group_violin(plt_mu.wins,'colors',[0 1 0;1 0 0;0 1 0;1 0 0],'width',.6,'bandwidth',.25,'withingroup_spacing',1.5)

group_center(1)=mean([tmp(1).MedianPlot.XData tmp(2).MedianPlot.XData]);
group_center(2)=mean([tmp(3).MedianPlot.XData tmp(4).MedianPlot.XData]);

set(gca,'XTick',group_center,'XTickLabel',{'NAc','DLS'});
ylabel('RMS changepoint-triggered ave. (Z)');
xlim([-2 6])
ylims=ylim();
ylim([0 ylims(2)]);    
schfigure.outify_axis;
schfigure.sparsify_axis([],[],'y');





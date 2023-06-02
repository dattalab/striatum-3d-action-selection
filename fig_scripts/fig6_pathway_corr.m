%%

if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/1pimaging_dls/phanalysis_object.mat');
    phan=phanalysis_object;
end


%%
%
%
%


d1d1={};
d1d2={};
d2d2={};
d2d1={};
d1centroids={};
d2centroids={};
rnds_d1d2={};
rnds_d2d1={};
rnds_d1d1={};
rnds_d2d2={};
d1rois=[];
d2rois=[];

nrands=1e3;
counter=1;
[b,a]=ellip(3,.2,40,[.5 1]/15,'bandpass');
compare_fun=@nanmean;
agg_fun=@nanmean;

for i=1:length(phan.session)
   fields=fieldnames(phan.imaging(i).traces);
   if any(strcmp(fields,'cell_type'))      

        
        consider_points=phan.projections(i).scalars.velocity_mag_3d;
        consider_points1=phan.metadata.time_mappers{i}(consider_points);
        consider_points1=consider_points1>=prctile(consider_points1,50)&...
            consider_points1<=prctile(consider_points1,100);
        consider_points2=conv(abs(diff(phan.behavior(i).labels))>0,ones(300,1)/300,'same');
        consider_points2=[nan;consider_points2]>0;


        all_traces=phanalysis.nanzscore([phan.imaging(i).traces(:).raw]);
        all_traces(all_traces<0)=0;
        all_traces=all_traces(consider_points1,:);        
        all_traces(any(isnan(all_traces)'),:)=[];

        cell_types={phan.imaging(i).traces(:).cell_type};
    
        % syll response
         nrois=size(all_traces,2);
         cmat=corr(all_traces,'rows','complete','type','pearson');

        d1idx=strcmp(cell_types,'d1');
        d2idx=strcmp(cell_types,'d2');
        d1idxidx=find(d1idx);
        d2idxidx=find(d2idx);
        
        d1rois(end+1)=sum(d1idx);
        d2rois(end+1)=sum(d2idx);
        cmat(eye(size(cmat))==1)=nan;
        
        submat=cmat(d1idx,d1idx);
        %submat(triu(ones(size(submat)))==0)=nan;
        d1d1{counter}=compare_fun(submat);
        
        submat=cmat(d2idx,d1idx);
        d1d2{counter}=compare_fun(submat);
        
        submat=cmat(d2idx,d2idx);
        d2d2{counter}=compare_fun(submat);
        
        submat=cmat(d1idx,d2idx);
        d2d1{counter}=compare_fun(submat);
        
        subcmat=cmat(d1idx|d2idx,d1idx|d2idx);
        rndpool=1:size(subcmat,1);        
        
        for j=1:nrands
            rndsel=rndpool(randperm(size(subcmat,1)));
            rndsel1=rndsel(1:sum(d1idx));
            rndsel2=rndsel(sum(d1idx)+1:sum(d1idx)+sum(d2idx));
      
            submat=subcmat(rndsel2,rndsel1);
            rnds_d1d2{counter,j}=compare_fun(submat);
            submat=subcmat(rndsel1,rndsel2);
            rnds_d2d1{counter,j}=compare_fun(submat);
            submat=subcmat(rndsel2,rndsel2);
            rnds_d2d2{counter,j}=compare_fun(submat);            
            submat=subcmat(rndsel1,rndsel1);
            rnds_d1d1{counter,j}=compare_fun(submat);
        end
      
        counter=counter+1;    

   end    
end

%% plotting


pathway_comparison=schfigure();
pathway_comparison.name='twocolor_withintrialcorr';
pathway_comparison.dims='3x3';
pathway_comparison.formats='png,pdf,fig';

tmp1=cat(2,d1d1{:});
tmp2=cat(2,d1d2{:});
tmp3=cat(2,d2d2{:});
tmp4=cat(2,d2d1{:});

subplot(2,2,1);
schfigure.stair_histogram(tmp1,[-.1:.025:.7],'normalize',true,'cdf',true,'k-','color','r')
hold on;
schfigure.stair_histogram(tmp2,[-.1:.025:.7],'normalize',true,'cdf',true,'k-','color','g')
xlim([-.1 .6]);
schfigure.outify_axis;
schfigure.sparsify_axis;
xlabel('ROI to ROI corr.');
ylabel('Frac.');

subplot(2,2,3);

rnds_mu=nan(1,nrands);
for j=1:nrands
    rnds_mu(j)=agg_fun(cat(2,rnds_d1d2{:,j}));
end

schfigure.stair_histogram(rnds_mu,[0:.0025:.25],'normalize',false,'k-','color','k')
hold on;
ylims=ylim();
plot(repmat(agg_fun(tmp1),[1 2]),ylims(),'r-');
plot(repmat(agg_fun(tmp2),[1 2]),ylims(),'g-');

xlim([.05 .2]);
schfigure.outify_axis;
schfigure.sparsify_axis;
xlabel('Ave corr.');
ylabel('Count');


subplot(2,2,2);
schfigure.stair_histogram(tmp3,[-.1:.025:.7],'normalize',true,'cdf',true,'k-','color','g')
hold on;
schfigure.stair_histogram(tmp4,[-.1:.025:.7],'normalize',true,'cdf',true,'k-','color','r')
xlim([-.1 .6]);
schfigure.outify_axis;
schfigure.sparsify_axis;
xlabel('ROI to ROI corr.');
ylabel('Frac.');

subplot(2,2,4);

rnds_mu=nan(1,nrands);
for j=1:nrands
    rnds_mu(j)=agg_fun(cat(2,rnds_d2d1{:,j}));
end

schfigure.stair_histogram(rnds_mu,[0:.0025:.25],'normalize',false,'k-','color','k')
hold on;
ylims=ylim();
plot(repmat(agg_fun(tmp3),[1 2]),ylims(),'g-');
plot(repmat(agg_fun(tmp4),[1 2]),ylims(),'r-');
xlim([.05 .2]);
schfigure.outify_axis;
schfigure.sparsify_axis;
xlabel('Ave corr.');
ylabel('Count');

%%

zd1d2={};
zd1d1={};
zd1_diff={};
for i=1:length(d1d2)
    mu=mean(cat(1,rnds_d1d2{i,:}));
    sig=std(cat(1,rnds_d1d2{i,:}));
    zd1d2{i}=(d1d2{i}-mu)./sig;  
%     
%     mu=mean(cat(1,rnds_d1d1{i,:}));
%     sig=std(cat(1,rnds_d1d1{i,:}));
    zd1d1{i}=(d1d1{i}-mu)./sig;
    zd1_diff{i}=zd1d1{i}-zd1d2{i};
end


zd2d1={};
zd2d2={};
zd2_diff={};

for i=1:length(d1d2)
    mu=mean(cat(1,rnds_d2d1{i,:}));
    sig=std(cat(1,rnds_d2d1{i,:}));
    zd2d1{i}=(d2d1{i}-mu)./sig;    
    
%     
%     mu=mean(cat(1,rnds_d2d2{i,:}));
%     sig=std(cat(1,rnds_d2d2{i,:}));
    zd2d2{i}=(d2d2{i}-mu)./sig;        
    zd2_diff{i}=zd2d2{i}-zd2d1{i};
end

norm_d1d1={};
norm_d2d2={};

for i=1:length(d1d1)
    norm_d1d1{i}=(d1d1{i}-d1d2{i})./(d1d1{i}+d1d2{i});
end

for i=1:length(d1d1)
    norm_d2d2{i}=(d2d2{i}-d2d1{i})./(d2d2{i}+d2d1{i});
end

%%

d2_dfs={};
nrands=1e3;
for i=1:length(d2d2)
    len1=length(d2d2{i});
    len2=length(d2d1{i});
    rndpool=[d2d2{i} d2d1{i}];
    rnd_dfs=nan(nrands,len1);
    for j=1:nrands
        sel=randperm(length(rndpool));
        pop1=rndpool(sel(1:len1));
        pop2=rndpool(sel(len1+1:len1+len2));
        rnd_dfs(j,:)=pop1-pop2;
    end
    mu=mean(rnd_dfs);
    sig=std(rnd_dfs);
    d2_dfs{i}=((d2d2{i}-d2d1{i})-mu)./sig;
end

d1_dfs={};
nrands=1e3;
for i=1:length(d2d2)
    len1=length(d1d1{i});
    len2=length(d1d2{i});
    rndpool=[d1d1{i} d1d2{i}];
    rnd_dfs=nan(nrands,len1);
    for j=1:nrands
        sel=randperm(length(rndpool));
        pop1=rndpool(sel(1:len1));
        pop2=rndpool(sel(len1+1:len1+len2));
        rnd_dfs(j,:)=pop1-pop2;
    end
    mu=mean(rnd_dfs);
    sig=std(rnd_dfs);
    d1_dfs{i}=((d1d1{i}-d1d2{i})-mu)./sig;
end


%%


pathway_comparison(2)=schfigure();
pathway_comparison(2).name='twocolor_withintrialcorr_boots_highchangepoint';
pathway_comparison(2).dims='3x3';
pathway_comparison(2).formats='png,pdf,fig';

smps_d1d1=bootstrp(1e3,agg_fun,cat(2,d1d1{:}));
smps_d1d2=bootstrp(1e3,agg_fun,cat(2,d1d2{:}));
smps_d2d2=bootstrp(1e3,agg_fun,cat(2,d1d1{:}));
smps_d2d1=bootstrp(1e3,agg_fun,cat(2,d2d1{:}));

bins=[0.05:.0025:.2];
ax=[];
ax(1)=subplot(2,1,1);
schfigure.stair_histogram(smps_d1d1,bins,'color','r','cdf',false,'normalize',false);
hold on;
schfigure.stair_histogram(smps_d1d2,bins,'color','g','cdf',false,'normalize',false);
box off;
schfigure.outify_axis
ylabel('Count (D1)');

ax(2)=subplot(2,1,2);
schfigure.stair_histogram(smps_d2d2,bins,'color','g','cdf',false,'normalize',false);
hold on;
schfigure.stair_histogram(smps_d2d1,bins,'color','r','cdf',false,'normalize',false);
box off;
xlabel('Average corr (r)');
ylabel('Count (D2)');
linkaxes(ax,'xy');
xlim([0.075 .2]);
schfigure.outify_axis

%%

pathway_comparison(3)=schfigure();
pathway_comparison(3).name='twocolor_withintrialcorr_reduced';
pathway_comparison(3).dims='3x1.5';
pathway_comparison(3).formats='png,pdf,fig';

tmp1=cat(2,d1d1{:});
tmp2=cat(2,d1d2{:});
tmp3=cat(2,d2d2{:});
tmp4=cat(2,d2d1{:});

ax=[];
ax(1)=subplot(1,2,1);

rnds_mu=nan(1,nrands);
for j=1:nrands
    rnds_mu(j)=agg_fun(cat(2,rnds_d1d2{:,j}));
end

schfigure.stair_histogram(rnds_mu,[0:.002:.25],'normalize',false,'k-','color','k')
hold on;
ylims=ylim();
plot(repmat(agg_fun(tmp1),[1 2]),[0 500],'r-');
plot(repmat(agg_fun(tmp2),[1 2]),[0 500],'g-');

xlim([.05 .2]);
schfigure.outify_axis;
schfigure.sparsify_axis;
xlabel('Ave corr.');
ylabel('Count');

ax(2)=subplot(1,2,2);

rnds_mu=nan(1,nrands);
for j=1:nrands
    rnds_mu(j)=agg_fun(cat(2,rnds_d2d1{:,j}));
end

schfigure.stair_histogram(rnds_mu,[0:.002:.25],'normalize',false,'k-','color','k')
hold on;
ylims=ylim();
plot(repmat(agg_fun(tmp3),[1 2]),[0 500],'g-');
plot(repmat(agg_fun(tmp4),[1 2]),[0 500],'r-');

xlabel('Ave corr.');
ylabel('Count');
linkaxes(ax,'xy');
xlim([.11 .17]);
ylim([0 300]);
schfigure.outify_axis;
schfigure.sparsify_axis;



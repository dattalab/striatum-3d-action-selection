%%
%

if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/photometry_dls/phanalysis_object.mat');
    phan=phanalysis_object;
end

%%

phan.set_option('normalize_method','');
phan.set_option('rectify',false);
phan.set_option('filter_trace',false);

use_gcamp=[phan.session(:).use_gcamp]&[phan.session(:).has_photometry];
use_rcamp=[phan.session(:).use_rcamp]&[phan.session(:).has_photometry];

phot=phan.photometry;

r_rcamp=[];
r_gcamp=[];
bin_sizes=cumprod([3 ones(1,10)*2]);
overlap=1;
upd=kinect_extract.proc_timer(length(phot)*length(bin_sizes));
counter=1;

shift=0;
clear d1_bins d2_bins;

d1_bins=struct();
d2_bins=struct();

use_scalars={'velocity_mag'};
use_scalars(contains(use_scalars,'centroid'))=[];
use_scalars(contains(use_scalars,'pca'))=[];
use_scalars(contains(use_scalars,'velocity_theta'))=[];
time_clips=[1 inf];

rmsfun=@nanmean;
rmsfun_scalar=@nanmean;

for ii=1:length(bin_sizes)
    
    for i=1:length(use_scalars)
        d1_bins.(use_scalars{i}){ii}=[];
        d2_bins.(use_scalars{i}){ii}=[];
        use_field_dt=sprintf('%s_dt',use_scalars{i});
        d1_bins.(use_field_dt){ii}=[];
        d2_bins.(use_field_dt){ii}=[];
    end
    
    for i=1:length(phot)
        
        nsamples=numel(phan.projections(i).scalars.velocity_mag);
        nsamples=min(nsamples,time_clips(2));
        
        sample_idx=[max(time_clips(1),1):nsamples];        
        nsamples=max(sample_idx)-min(sample_idx);
        
        put_idx=~isnan(phan.projections(i).proj_idx);        
        put_vector=nan(nsamples,1);
        
        bin_edges=unique([sample_idx(1) sample_idx(1):bin_sizes(ii):sample_idx(end) sample_idx(end)]);
        [~,~,bin_idx]=histcounts(sample_idx,bin_edges);
        bin_idx=bin_idx(:);
        
        new_edges=bin_edges;
        
        for j=1:overlap-1
            new_edges=new_edges+round(bin_sizes(ii)/overlap);
            [~,~,bin_idx(:,j+1)]=histcounts(sample_idx,new_edges);
        end
        
        bin_idx(bin_idx==0)=1;
        
        %bin_idx=bin_idx(:);
        nbins=length(unique(bin_idx));
        
        if use_gcamp(i)
            tmp=phanalysis.nanzscore((phan.normalize_trace(phot(i).traces(1).dff)));
            put_vector=nan(nsamples,1);
            put_vector(put_idx)=tmp;
            put_vector=(put_vector(sample_idx));
            put_vector=circshift(put_vector,shift);
            tmp_phot_gcamp=[];
            for j=1:size(bin_idx,2)
                tmp_phot_gcamp(:,j)=(accumarray(bin_idx(:,j),put_vector,[max(bin_idx(:)) 1],rmsfun));
            end
        end
        
        if use_rcamp(i)
            tmp=phanalysis.nanzscore((phan.normalize_trace(phot(i).traces(4).dff)));

            put_vector=nan(nsamples,1);
            put_vector(put_idx)=tmp;
            put_vector=(put_vector(sample_idx));

            put_vector=circshift(put_vector,shift);
            tmp_phot_rcamp=[];
            for j=1:size(bin_idx,2)
                tmp_phot_rcamp(:,j)=(accumarray(bin_idx(:,j),put_vector,[max(bin_idx(:)) 1],rmsfun));
            end
        end
        
        for j=1:length(use_scalars)
            
            use_scalar=(phan.projections(i).scalars.(use_scalars{j}));
            use_scalar=(use_scalar(sample_idx));
            use_scalar_dt=[nan;diff(use_scalar)];
            
            tmp_scalar=[];
            tmp_scalar_dt=[];
            
            for k=1:size(bin_idx,2)
                tmp_scalar(:,k)=(accumarray(bin_idx(:,k),use_scalar,[max(bin_idx(:)) 1],rmsfun_scalar));
                tmp_scalar_dt(:,k)=(accumarray(bin_idx(:,k),use_scalar_dt,[max(bin_idx(:)) 1],rmsfun_scalar));
            end
            
            use_field_dt=sprintf('%s_dt',use_scalars{j});
            
            if use_gcamp(i)
                d2_bins.(use_scalars{j}){ii}=[d2_bins.(use_scalars{j}){ii};[tmp_phot_gcamp(:) tmp_scalar(:)]];
                d2_bins.(use_field_dt){ii}=[d2_bins.(use_field_dt){ii};[tmp_phot_gcamp(:) tmp_scalar_dt(:)]];              
            end
            
            if use_rcamp(i)
                d1_bins.(use_scalars{j}){ii}=[d1_bins.(use_scalars{j}){ii};[tmp_phot_rcamp(:) tmp_scalar(:)]];
                d1_bins.(use_field_dt){ii}=[d1_bins.(use_field_dt){ii};[tmp_phot_rcamp(:) tmp_scalar_dt(:)]];       
            end
            
        end
        
        upd(counter);
        counter=counter+1;
        
    end
end

%%

velocity_fig=schfigure();
velocity_fig.name='velocity_timescale';
velocity_fig.dims='5x2';
corrfun=@(x) corr((x(:,1)),(x(:,2)),'type','pearson','rows','pairwise');
plt_scalars=fieldnames(d1_bins);
plt_scalars(strcmp(plt_scalars,'angle'))=[];
nrows=ceil(numel(plt_scalars)/2);

for i=1:length(plt_scalars)
    
    subplot(nrows,2,i);
    plot(bin_sizes/30,cellfun(corrfun,d1_bins.(plt_scalars{i})),'r.-','markersize',10)
    hold on
    plot(bin_sizes/30,cellfun(corrfun,d2_bins.(plt_scalars{i})),'g.-','markersize',10)
    xlim([0 450]);
    %ylim([-.5 .5]);
    
    box off;
    if i==1
        ylabel('Correlation (r)');    
    end
    
    if i==length(plt_scalars)
        xlabel('Bin size (s)');
    end
    
    title(regexprep(plt_scalars{i},'_',' '));
    
    ylim([-.1 .3]);
    xlim([bin_sizes(1)/30 bin_sizes(end)/30]);
    %plot(get(gca,'xlim'),[0 0],'k--');
    
    schfigure.sparsify_axis([],[],[],[],[-.05 0 1]);
    schfigure.outify_axis;
    %schfigure.sparsify_axis(gca,[],[],[],[-.05 0 .4]);
    
%     use_field_dt=sprintf('%s_dt',plt_scalars{i});
% 
%     
%     subplot(8,2,(i-1)*2+2);
%     plot(bin_sizes/30,cellfun(corrfun,d1_bins.(use_field_dt)),'r.-','markersize',10)
%     hold on
%     plot(bin_sizes/30,cellfun(corrfun,d2_bins.(use_field_dt)),'g.-','markersize',10)
%     xlim([0 450]);
%     %ylim([-.5 .55]);
%     box off;
%     %schfigure.sparsify_axis(gca,[],[],[],[-.05 0 .15]);
%     schfigure.outify_axis;
    
end
%%

% plot dem results homay

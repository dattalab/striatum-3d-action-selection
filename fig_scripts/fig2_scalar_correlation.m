% assumes the photometry phanalysis object has been loaded in 

if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/photometry_dls/phanalysis_object.mat');
    phan=phanalysis_object;
end


%%
% which fields to plot

print_stats=true;
chk_fields={'angle_dt',...
    'height_ave',...
    'height_ave_dt',...
    'length',...
    'length_dt',...
    'velocity_mag',...
    'velocity_mag_dt',...
    'velocity_mag_3d',...
    'velocity_mag_3d_dt'};
ratio_alpha=1e-5;

% shuffles

%% 
% gather the data and run the correlations

scalar_cat=struct();
scalar_cat.gcamp=[];
scalar_cat.rcamp=[];
%scalar_cat.ratio=[];
scalar_cat.df=[];

idx=struct();
idx.gcamp=find(~cellfun(@isempty,{phan.stats.corr_phot(:).gcamp}));
idx.rcamp=find(~cellfun(@isempty,{phan.stats.corr_phot(:).rcamp}));

idx.df=intersect(idx.gcamp,idx.rcamp);
idx.ratio=intersect(idx.gcamp,idx.rcamp);

time_clips=[1 inf];
spacing=1;
norm_fun=@(x) phanalysis.nanzscore(x);
norm_fun_scalar=norm_fun;

for i=idx.gcamp
    sz=length(phan.stats.corr_phot(i).gcamp);
    scalar_cat.gcamp=[scalar_cat.gcamp;norm_fun(phan.stats.corr_phot(i).gcamp(time_clips(1):spacing:min(time_clips(2),sz)))];
end

for i=idx.rcamp
    sz=length(phan.stats.corr_phot(i).rcamp);
    scalar_cat.rcamp=[scalar_cat.rcamp;norm_fun(phan.stats.corr_phot(i).rcamp(time_clips(1):spacing:min(time_clips(2),sz)))];
end

for i=idx.df
    sz=length(phan.stats.corr_phot(i).rcamp);
    scalar_cat.df=[scalar_cat.df;(norm_fun(phan.stats.corr_phot(i).rcamp(time_clips(1):spacing:min(time_clips(2),sz)))...
        -norm_fun(phan.stats.corr_phot(i).gcamp(time_clips(1):spacing:min(time_clips(2),sz))))];
end

conditions=fieldnames(scalar_cat);

for i=1:length(chk_fields)
    for j=1:length(conditions)
        tmp=[];
        for k=1:length(idx.(conditions{j}))
            use_data=phan.stats.corr_scalars(idx.(conditions{j})(k)).(chk_fields{i});
            sz=length(use_data);
            tmp=[tmp;(use_data(time_clips(1):spacing:min(time_clips(2),sz)))];
        end
        scalar_cat.(conditions{j})(:,i+1)=tmp;
    end
end

for i=1:length(conditions)    
   scalar_cat.(conditions{j})=(scalar_cat.(conditions{j})); 
end

%%

conditions=fieldnames(scalar_cat);

nboots=phan.user_data.nboots;
r=struct();
p=struct();
boots=struct();
corr_type='pearson';
bootf=@(x, y) corr(norm_fun(x), norm_fun_scalar(y), 'rows', 'complete', 'type', corr_type);
sigs = struct();
opts=statset('UseParallel',true);

for i=1:length(conditions)
     bootstat = bootstrp(nboots, bootf, ...
         scalar_cat.(conditions{i})(:, 1), scalar_cat.(conditions{i})(:, 2:end),'options',opts);
     boots.(conditions{i}) = bootstat;
    [r.(conditions{i}), p.(conditions{i})]=bootf(...
        scalar_cat.(conditions{i})(:, 1), ...
        scalar_cat.(conditions{i})(:, 2:end));
    %sigs.(conditions{i}) = mean(bootstat > repmat(r.(conditions{i}),[numsimulations 1])) + 1/numsimulations;
end

%%
% plotting code and save everything

labels=cell(1,length(chk_fields));

for i=1:length(chk_fields)
    labels{i}=regexprep(chk_fields{i},'\_',' ');
    labels{i}=regexprep(labels{i},' mag','');
    
    labels{i}=regexprep(labels{i},' ave','');
    if contains(labels{i},' dt')
       labels{i}=regexprep(labels{i},' dt','');
       labels{i}=['\Delta(' labels{i} ')'];
    end
end

alpha1=.05;
alpha2=1e-10;

d1d2_scalar=schfigure();
d1d2_scalar.name='d1d2_scalar_bar_d1cre';
d1d2_scalar.dims='2x2.4';
d1d2_scalar.formats='pdf,png,fig';
schfigure.sparsify_axis;
schfigure.outify_axis;
%b=bar([r.rcamp;r.gcamp;r.ratio]');

b=bar([r.rcamp;r.gcamp;r.df]','edgecolor','none');
b(1).FaceColor=[1 0 0];
b(2).FaceColor=[0 1 0];
b(3).FaceColor=[.75 .75 0];
hold on;

plt_conditions={'rcamp','gcamp','df'};

for i=1:length(plt_conditions)
    plot(repmat(b(i).XData+b(i).XOffset,[2 1]),...
        prctile(boots.(plt_conditions{i}),[.5 99.5]),'k-');
end

view(90,90)
ylim([-.25 .25]);

ylims=ylim();
offset=range(ylims())/12;
markersize=2;

for i=1:length(plt_conditions)
    p1=p.(plt_conditions{i})>alpha2&p.(plt_conditions{i})<alpha1;
    p2=p.(plt_conditions{i})<alpha2&~p1;
    star_ax=[];
    if any(p1)
        star_ax(end+1)=plot([b(i).XData(p1)+b(i).XOffset],...
            [r.(plt_conditions{i})(p1)+offset*sign(r.(plt_conditions{i})(p1))],...
            'k*','markersize',markersize);
    end
    if any(p2)
        star_ax(end+1)=plot([b(i).XData(p2)+b(i).XOffset],...
            [r.(plt_conditions{i})(p2)+offset*sign(r.(plt_conditions{i})(p2))],...
            'k*','markersize',markersize);
        star_ax(end+1)=plot([b(i).XData(p2)+b(i).XOffset],...
            [r.(plt_conditions{i})(p2)+offset*1.75*sign(r.(plt_conditions{i})(p2))],...
            'k*','markersize',markersize);
    end
    if ~isempty(star_ax)
        set(star_ax,'Clipping','off');
    end
end

schfigure.sparsify_axis([],1e-2,'y');
schfigure.outify_axis;
ylabel('Correlation (r)');
set(gca,'XTickLabel',labels,'FontSize',8)

%d1d2_scalar.save_figure;

if print_stats
    for i=1:length(conditions)
        use_fields=chk_fields;
        for j=1:length(chk_fields)
            use_fields{j}=sprintf('r=%g %s',r.(conditions{i})(j),chk_fields{j});
        end
        phanalysis.print_stats(sprintf('scalar_correlations_update_%s.txt',conditions{i}),phanalysis.holm_bonf(p.(conditions{i})),use_fields);
    end
    save('scalar_correlations_update.mat','p','boots','r','scalar_cat','ratio_alpha','idx');
end


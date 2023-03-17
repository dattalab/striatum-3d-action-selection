%%

if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/1pimaging_dls/phanalysis_object.mat');
    phan=phanalysis_object;
end



%%

%

example=16;
zoom_out=[460 510];
zoom_in=[484 495];
color_scale=[0 2];

all_data=phanalysis.nanzscore([phan.imaging(example).traces(:).raw]);
beh=phan.behavior;

ca_colors='parula';
tvec=[1:size(all_data,1)]/phan.imaging(example).metadata.fs;
beh_segment=beh(example).labels;
[uniq_labels,~,ic]=unique(beh_segment);

cadata_fig(1)=schfigure;
cadata_fig(1).dims='4x2';
cadata_fig(1).name='ca_example_zoomout';
cadata_fig(1).formats='pdf,png,fig';

ax(1)=subplot(3,1,1);
h=imagesc(tvec,[],ic');
h.CDataMapping='direct';
colors=colormap(distinguishable_colors(length(uniq_labels)));
colormap(ax(1),colors);
axis off;

ax(2)=subplot(3,1,2:3);
imagesc(tvec,[],all_data');
axis xy;
schfigure.sparsify_axis(gca);
schfigure.outify_axis(gca);
hold on;
h=plot([zoom_out(1) zoom_out(1)+10],[-10 -10],'k-');
h.Clipping='off';
ylims=ylim();
h=plot([zoom_in],[ones(1,2)*(ylims(2)+10)],'k-');
h.Clipping='off';
colormap(ax(2),ca_colors)
caxis(color_scale);
axis off;
hold on;
linkaxes(ax,'x');
xlim(zoom_out);
c=colorbar('Location','EastOutside');
set(c,'XTick',color_scale);
drawnow;
ax1pos=get(ax(1),'position');
ax2pos=get(ax(2),'position');
set(ax(1),'position',[ax1pos(1:2) ax2pos(3) ax1pos(4)]);


%%

cadata_fig(2)=schfigure;
cadata_fig(2).dims='4x2';
cadata_fig(2).name='ca_example_zoomin';
cadata_fig(2).formats='pdf,png,fig';
ax(1)=subplot(3,1,1);
h=imagesc(tvec,[],ic');
h.CDataMapping='direct';
colors=colormap(distinguishable_colors(length(uniq_labels)));
colormap(ax(1),colors);
axis off;

ax(2)=subplot(3,1,2:3);
imagesc(tvec,[],all_data');
axis xy;
schfigure.sparsify_axis(gca);
schfigure.outify_axis(gca);
colormap(ax(2),ca_colors)
caxis(color_scale);
axis off;
hold on;
linkaxes(ax,'x');
xlim(zoom_in);
h=plot([zoom_in(1) zoom_in(1)+1],[-10 -10],'k-');
h.Clipping='off';
c=colorbar('Location','EastOutside');
set(c,'XTick',color_scale);
drawnow;
ax1pos=get(ax(1),'position');
ax2pos=get(ax(2),'position');
set(ax(1),'position',[ax1pos(1:2) ax2pos(3) ax1pos(4)]);
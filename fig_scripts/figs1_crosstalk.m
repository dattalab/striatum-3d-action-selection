%%

phot=struct();
load('~/Desktop/phanalysis_images/photometry_crosstalk/both/hifiber_object.mat');
phot.both=hifiber_object;
clear hifiber_object;


load('~/Desktop/phanalysis_images/photometry_crosstalk/greenonly/hifiber_object.mat');
phot.green=hifiber_object;
clear hifiber_object;

load('~/Desktop/phanalysis_images/photometry_crosstalk/redonly/hifiber_object.mat');
phot.red=hifiber_object;
clear hifiber_object;

% assumes we've loaded in all of the relevant objects;

crosstalk=schfigure;
crosstalk.name='crosstalk_panels';
crosstalk.dims='9x4';

subplot(1,4,1);
tvec=[1:length(phot.green.traces(1).raw)]/phot.green.metadata.fs;
plot(tvec,phot.green.traces(1).raw*1e3,'g-');
hold on;
plot(tvec,phot.green.traces(4).raw*1e3,'r-');
xlim([0 200]);
schfigure.outify_axis;
schfigure.sparsify_axis;
title('Green LED only');
ylabel('PMT amplitude (V)');
xlabel('Time (s)');

subplot(1,4,2);
tvec=[1:length(phot.red.traces(1).raw)]/phot.green.metadata.fs;

plot(tvec,phot.red.traces(1).raw*1e3,'g-');
hold on;
plot(tvec,phot.red.traces(4).raw*1e3,'r-');
xlim([0 200]);
schfigure.outify_axis;
schfigure.sparsify_axis;
title('Red LED only');



subplot(1,4,3);
tvec=[1:length(phot.both.traces(1).raw)]/phot.green.metadata.fs;

plot(tvec,phot.both.traces(1).raw*1e3,'g-');
hold on;
plot(tvec,phot.both.traces(4).raw*1e3,'r-');
xlim([0 200]);
schfigure.outify_axis;
schfigure.sparsify_axis([],.1);
title('Both LEDs');

chk={'red','green','both'};
r=struct();
for i=1:length(chk)
    r.(chk{i})= corr(phot.(chk{i}).traces(1).raw,phot.(chk{i}).traces(4).raw,'rows','pairwise')
end

subplot(1,4,4);
b1=bar(1,r.green);
hold on;
b2=bar(2,r.red);
b3=bar(3,r.both);
b1.FaceColor=[0 1 0];
b2.FaceColor=[1 0 0];
b3.FaceColor=[1 1 0];
ylim([-.1 1]);
schfigure.outify_axis;
schfigure.sparsify_axis([],[],'y');
set(gca,'XTick',[1:3],'XTickLabel',{'Green','Red','Both'});

%%


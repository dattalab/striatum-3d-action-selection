%%


if ~exist('phan','var')
    load('~/Desktop/phanalysis_images/dls_lesion_round1/phanalysis_object.mat');
    phan=phanalysis_object;
end

beh=phan.behavior;

%%

beh=phan.behavior; % get the behavior object
beh.get_transition_matrix([1 36e3]); % which frames to analyze? 
beh.sort_states_by_usage(true);
[~,usage]=beh.get_syllable_usage;
phan.set_option('syllable_cutoff',max(find(usage>.01))); % which syllables to include in our analysis
phan.compute_usage_distance; 
cut=max(find(usage>0.01));

%%

% convenience variables for indexing 

% move a mouse to excluded to exclude from everything downstream

lesions={'15293','15294','15295'}
shams={'15296','15297'};
excluded_lesions={''};

session_name=lower({phan.session(:).session_name});
ids=regexprep(lower({phan.session(:).mouse_id}),'-.*','');

pre_odor=contains(session_name,'pre')|(contains(session_name,'petri')&~contains(session_name,'tmt')&~contains(session_name,'post'));
post_odor=contains(session_name,'post');
odor=contains(session_name,'tmt')|contains(session_name,'odor');
ctrl=~(pre_odor|post_odor|odor);


session_data=struct();
for i=1:length(ids)
    
    if any(strcmpi(ids{i},excluded_lesions))
        continue;
    end
    
    session_data.(['m' ids{i}])=struct('pre',[],'post',[],'ctrl',[],'odor',[]);
end

session_data=orderfields(session_data);

for i=1:length(session_name)
    
    if any(strcmpi(ids{i},excluded_lesions))
        continue;
    end
    
    if pre_odor(i)
        session_data.(['m' ids{i}]).pre(end+1)=i;
    elseif post_odor(i)
        session_data.(['m' ids{i}]).post(end+1)=i;
    elseif odor(i)
        session_data.(['m' ids{i}]).odor(end+1)=i;
    else
        session_data.(['m' ids{i}]).ctrl(end+1)=i;
    end
    
end


group_data=struct();
mnames=fieldnames(session_data);
mid={};

for i=1:length(mnames)
    if any(strcmpi(mnames{i}(2:end),lesions))
        mid{i}='lesion';
    else
        mid{i}='sham';
    end
end

for i=1:length(mnames)
    tmp1=cellfun(@(x) x.ctrl(1),struct2cell(session_data),'UniformOutput',false);
    tmp2=cellfun(@(x) x.ctrl(2),struct2cell(session_data),'UniformOutput',false);
    tmp3=cellfun(@(x) x.ctrl(3),struct2cell(session_data),'UniformOutput',false);
    tmp4=cellfun(@(x) x.odor,struct2cell(session_data),'UniformOutput',false);
    use_idx=strcmpi(mid,'lesion');
    
    group_data.ctrl.lesion.session1=cat(2,tmp1{use_idx});
    group_data.ctrl.lesion.session2=cat(2,tmp2{use_idx});
    group_data.ctrl.lesion.session3=cat(2,tmp3{use_idx});
    
    group_data.ctrl.sham.session1=cat(2,tmp1{~use_idx});
    group_data.ctrl.sham.session2=cat(2,tmp2{~use_idx});
    group_data.ctrl.sham.session3=cat(2,tmp3{~use_idx});
    
    group_data.odor.lesion=cat(2,tmp4{use_idx});
    group_data.odor.sham=cat(2,tmp4{~use_idx});
end

%%
% jsd analysis
jsd_compare=struct();
jsd_compare.first.same={};
jsd_compare.first.diff={};
jsd_compare.zero.same={};
jsd_compare.zero.diff={};

sessions=fieldnames(group_data.ctrl.lesion);

for i=1:length(sessions)
    
    same_condition=group_data.ctrl.lesion.(sessions{i});
    other_condition=group_data.ctrl.sham.(sessions{i});
    
    for j=1:length(same_condition)
        jsd_compare.first.same{end+1}=[];
        jsd_compare.first.diff{end+1}=[];
        jsd_compare.zero.same{end+1}=[];
        jsd_compare.zero.diff{end+1}=[];
        
        cur_idx=same_condition(j);
        chk_idx=setdiff(same_condition,cur_idx);
        
        for k=1:length(chk_idx)
            jsd_compare.zero.same{end}(end+1)=phan.distance.pr.jsd.zero(cur_idx,chk_idx(k));
            jsd_compare.first.same{end}(end+1)=phan.distance.pr.jsd.first(cur_idx,chk_idx(k));
        end
        
        for k=1:length(other_condition)
            jsd_compare.zero.diff{end}(end+1)=phan.distance.pr.jsd.zero(cur_idx,other_condition(k));
            jsd_compare.first.diff{end}(end+1)=phan.distance.pr.jsd.first(cur_idx,other_condition(k));
        end
    end
    
end


%%
% entropy

trans_to_p=@(x,alpha) bsxfun(@rdivide,x,sum(x,2));
trans_to_p_bigram=@(x) x./sum(x(:));

[~,usage]=beh.get_syllable_usage;
alpha=0;
fnames=sort(fieldnames(session_data));
ent=struct();

for i=1:length(fnames)
    for j=1:min(length(session_data.(fnames{i}).ctrl),3)
        trans_mat=single(beh(session_data.(fnames{i}).ctrl(j)).transition_matrix(1:cut,1:cut))+alpha;
        stationary=sum(trans_mat);
        stationary=(stationary(1:cut)')./sum(stationary(1:cut));
        pij=trans_to_p(single(trans_mat(1:cut,1:cut)));
        pij(pij==0)=nan;       
        ent.transp.firstorder.(fnames{i})(j)=-nansum(pij(:).*log(pij(:)));
        ent.transp.zeroorder.(fnames{i})(j)=-nansum(stationary(:).*log(stationary(:)));
        stationary=repmat(stationary,[1 cut]);
        ent.transp.rate.(fnames{i})(j)=-nansum(stationary(:).*pij(:).*log(pij(:)));
        ent.transp.mi.(fnames{i})(j)=ent.transp.zeroorder.(fnames{i})(j)-ent.transp.rate.(fnames{i})(j);
    end
end

for i=1:length(fnames)
    for j=1:min(length(session_data.(fnames{i}).ctrl),3)
        trans_mat=single(beh(session_data.(fnames{i}).ctrl(j)).transition_matrix(1:cut,1:cut))+alpha;
        stationary=sum(trans_mat);
        stationary=(stationary(1:cut)'+alpha)./sum(stationary(1:cut));
        pij=trans_to_p_bigram(single(trans_mat(1:cut,1:cut)));
        pij(pij==0)=nan;       
        ent.bigram.firstorder.(fnames{i})(j)=-nansum(pij(:).*log(pij(:)));
        ent.bigram.zeroorder.(fnames{i})(j)=-nansum(stationary(:).*log(stationary(:)));
        stationary=repmat(stationary,[1 cut]);
        ent.bigram.rate.(fnames{i})(j)=-nansum(stationary(:).*pij(:).*log(pij(:)));
        ent.bigram.mi.(fnames{i})(j)=ent.bigram.zeroorder.(fnames{i})(j)-ent.bigram.rate.(fnames{i})(j);
    end
end



%%
% usage differences...


sham_ctrls=struct2array(group_data.ctrl.sham);
sham_usages=[];

for i=1:length(sham_ctrls)
    [~,sham_usages(:,i)]=beh(sham_ctrls(i)).get_syllable_usage;
end

lesion_ctrls=struct2array(group_data.ctrl.lesion);
lesion_usages=[];

for i=1:length(lesion_ctrls)
    [~,lesion_usages(:,i)]=beh(lesion_ctrls(i)).get_syllable_usage;
end

[~,usages]=beh([sham_ctrls lesion_ctrls]).get_syllable_usage;
usage_cut=max(find(usages>.01));

lesion_usages=lesion_usages(1:usage_cut,:);
sham_usages=sham_usages(1:usage_cut,:);

total_mu=mean([sham_usages]')-mean([lesion_usages]');
[~,idx]=sort(total_mu,'descend');

sham_usages=sham_usages(idx,:);
lesion_usages=lesion_usages(idx,:);

sham_sem=std(bootstrp(1e3,@mean,sham_usages')).*1.96;
lesion_sem=std(bootstrp(1e3,@mean,lesion_usages')).*1.96;

sham_mu=mean(sham_usages');
lesion_mu=mean(lesion_usages');

p_usage=[];
for i=1:size(lesion_usages,1)
    [~,p_usage(i)]=ttest2(sham_usages(i,:),lesion_usages(i,:));
end

%p_usage=phanalysis.holm_bonf(p_usage);
p_usage=mafdr(p_usage,'bhfdr',true);
p_alpha=.05;

sig=find(p_usage<p_alpha);

sham_ci=[sham_mu-sham_sem;sham_mu+sham_sem];
lesion_ci=[lesion_mu-lesion_sem;lesion_mu+lesion_sem];

%% plotting

% jsd

% hypothesis test...
agg_function=@mean;

p_jsd.first=signrank(cellfun(agg_function,jsd_compare.first.diff),cellfun(agg_function,jsd_compare.first.same),'tail','right');
p_jsd.zero=signrank(cellfun(agg_function,jsd_compare.zero.diff),cellfun(agg_function,jsd_compare.zero.same),'tail','right');

jsd_fig=schfigure();
jsd_fig.dims='1.5x1.5';
jsd_fig.name='dls_jsd_ctrl_lesion_round1';
jsd_fig.formats='pdf,fig,png';

diff_v_sham_first=[cellfun(agg_function,jsd_compare.first.diff);cellfun(agg_function,jsd_compare.first.same)];
x=[zeros(1,size(diff_v_sham_first,2));ones(1,size(diff_v_sham_first,2))];

subplot(1,2,1);

plot(x,diff_v_sham_first,'k.-','markersize',20);
xlim([-.25 1.25]);
ylim([.15 .5]);

set(gca,'XTick',[],'FontSize',7);

schfigure.sparsify_axis([],.1,'y');
schfigure.outify_axis;

subplot(1,2,2);

diff_v_sham_zero=[cellfun(agg_function,jsd_compare.zero.diff);cellfun(agg_function,jsd_compare.zero.same)];
x=[zeros(1,size(diff_v_sham_zero,2));ones(1,size(diff_v_sham_zero,2))];
plot(x,diff_v_sham_zero,'k.-','markersize',20);
xlim([-.25 1.25]);
%ylim([10 17]);
set(gca,'XTick',[],'FontSize',7);
schfigure.sparsify_axis([],1e-2,'y');
schfigure.outify_axis;

old_diffs_zero=diff_v_sham_zero;
old_diffs_first=diff_v_sham_first;

% entropy

ent_fig=schfigure();
ent_fig.dims='1.25x1.5';
ent_fig.name=sprintf('dls_entropy_rate_all_cut%i_round1',cut);
ent_fig.formats='pdf,fig,png';

% interesting, mutual information may have an effect too (change 'rate' to
% 'mi')

ents=struct2cell(ent.bigram.rate);
group1=cat(2,ents{strcmp(mid,'sham')});
group2=cat(2,ents{strcmp(mid,'lesion')});
old_group1=group1;
old_group2=group2;

plot(ones(size(group1)),group1,'bo','markersize',5,'markerfacecolor',[1 1 1]);
hold on
plot(ones(size(group2))*2,group2,'ro','markersize',5,'markerfacecolor',[1 1 1]);
xlim([.5 2.5]);
set(gca,'XTick',[],'FontSize',7);
schfigure.sparsify_axis([],1e-2,'y');
schfigure.outify_axis;

% usages

xvec=[1:length(sham_mu)]*1.5;
offset=.15;
sham_color='b';
lesion_color='r';
usage_fig_dots=schfigure();
usage_fig_dots.dims='4x1.5';
usage_fig_dots.formats='pdf,fig,png';

usage_fig_dots.name='dls_usage_fig_dots_round1';

plot(xvec-offset,sham_mu,'b.','markersize',10);
hold on;
plot(repmat(xvec-offset,[2 1]),sham_ci,'b-');
plot(xvec+offset,lesion_mu,'r.','markersize',10);
plot(repmat(xvec+offset,[2 1]),lesion_ci,'r-');
ylim([0 .075]);
xlim([0 max(xvec)+xvec(1)]);
schfigure.outify_axis;
schfigure.sparsify_axis;
set(gca,'XColor','none');
ylims=ylim();
for i=1:length(sig)
    h=plot(xvec(sig(i)),-.005,'k*','markersize',6);
    h.Clipping='off';
end

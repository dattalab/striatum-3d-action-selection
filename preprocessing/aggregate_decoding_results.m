%%
% NOTE: this script must be run in the directory where decoding results
% were saved
%
% 1) decoding_results_imaging_pseudo_hierarchy/20180317T004533 (hierarchy, DOUBLE CHECK)
% 2) ncells decoding_results_imaging_pseudo_ncells/20180317T000947 (ncells)
% 3) ncells decoding_results_imaging_pseudo_ncells/20180320T090210 (fig 6)
% 4) decoding_results_twocolor_pseudopop/20180322T034820 (2color pseudopop)

% 1) decoding_results_withinanimal/20180118T105648 (agg and set to old_performance)
% 2) decoding_results_withinanimal_compare/20180118T105648 (agg and set to performance)

%%

listing=dir(fullfile(pwd,'rf_decoding*.mat'));
listing={listing(:).name};

grps={'d1','d2','both'};

upd=kinect_extract.proc_timer(length(listing));
performance=struct();

load('job_details.mat','pseudo_pop','pseudo_pop_labels');
load(listing{1},'metadata');

nfolds=metadata.nfolds;
nboots=metadata.nboots;

nrands=1e3;
nparams=length(listing);

performance.rnd=[];
performance.ncells=[];
performance.levels=[];,
performance.nsyllables={};
grps={'d1','d2','both'};
is_hierarchy=false;
is_ncells=true;

for i=1:nparams
    
    load(listing{i},'model_perf','model_prediction','metadata');
       
    % for now just load performance and construct guessing likelihood based
    % on prevalence order 0 probs 
           
    performance.ncells(i)=metadata.ncells;    
    
    if isfield(metadata,'hierarchy_labels')
        use_labels=metadata.hierarchy_labels(pseudo_pop_labels);
        is_hierarchy=true;
        performance.levels(i)=metadata.level;
        metadata.cell_idx=1;
        if ~isfield(metadata,'level_idx')
            metadata.level_idx=i;
        end
    else
        use_labels=pseudo_pop_labels;
        metadata.level_idx=1;
    end
    
    if ~isfield(metadata,'mouse_idx')
        metadata.mouse_idx=1;
    end
    
    if ~isfield(metadata,'cell_idx') & ~is_ncells
        metadata.cell_idx=1;
    elseif ~isfield(metadata,'cell_idx') & is_cells
        metadata.cell_idx=i;    
        
    end
    
    if isfield(metadata,'nboots') & ~isfield(metadata,'boot_idx')
        for j=1:length(grps)
            for k=1:nboots
                performance.(grps{j})(:,k,metadata.cell_idx,metadata.level_idx,metadata.mouse_idx)=model_perf.(grps{j})(k,:);        
            end
        end
    
    else
    
        for j=1:length(grps)
            performance.(grps{j})(:,metadata.boot_idx,metadata.cell_idx,metadata.level_idx,metadata.mouse_idx)=model_perf.(grps{j});        
        end
    end
    
    % flip that weighted coin
    
    for j=1:nfolds
       
        if any(use_labels==0)
            use_labels=use_labels+1;
        end
        
        use_labels_fold=use_labels(metadata.cvobj.training(j));
        obs_labels_fold=use_labels(metadata.cvobj.test(j));
                        
        probs=accumarray(use_labels_fold,ones(size(use_labels_fold)));
        probs=probs./sum(probs);
        bins=[-inf;cumsum(probs);inf];
        
        for k=1:nrands
            
            [~,guess]=histc(rand(length(obs_labels_fold),1),bins);
            performance.rnd(j,k,metadata.cell_idx,metadata.level_idx,metadata.mouse_idx)=mean(obs_labels_fold==guess);
            
        end
    end       
    
    performance.nsyllables{metadata.level_idx}=unique(use_labels);
        
    upd(i);
   
end

performance.rnd=squeeze(performance.rnd);

for i=1:length(grps)
    performance.(grps{i})=squeeze(performance.(grps{i}));
end

%%

if exist('old_performance', 'var')
    save('decoding_results.mat', 'performance', 'old_performance')
else
    save('decoding_results.mat', 'performance')
end
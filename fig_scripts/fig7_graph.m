tmp=schfigure();
savedir=tmp.working_dir;
delete(tmp.fig);

% take all control data from lesions and shams


use_example=i;
weight_threshold=1e-4;
degree_threshold=1e-3;

shams_idx=ismember(ids,shams)&ctrl;
lesions_idx=ismember(ids,lesions)&ctrl;

tmp=sum(cat(3,beh(shams_idx).transition_matrix),3);
shams_p=tmp./sum(tmp(:));
%shams_p(isnan(shams_p))=0;

tmp=sum(cat(3,beh(lesions_idx).transition_matrix),3);
lesions_p=tmp./sum(tmp(:));
%lesions_p(isnan(lesions_p))=0;

force_edges=shams_p>weight_threshold|lesions_p>weight_threshold;
use_example=1;

kinect_model.export_to_table(shams_p,...
    'output_file',fullfile(savedir,sprintf('graphs_session%i_weight%.04f_shams.txt',use_example,weight_threshold)),...
    'prune_weights',weight_threshold,'degree_threshold',degree_threshold,'force_edges',force_edges);

% force edges to include so we don't skip drawing anything in the prior
% graph

kinect_model.export_to_table(lesions_p,...
    'output_file',fullfile(savedir,sprintf('graphs_session%i_weight%.04f_lesions.txt',use_example,weight_threshold)),...
    'prune_weights',weight_threshold,'degree_threshold',degree_threshold,'force_edges',force_edges);

df=lesions_p-shams_p;

kinect_model.export_to_table(df,...
    'output_file',fullfile(savedir,sprintf('graphs_session%i_weight%.04f_df.txt',use_example,weight_threshold)),...
    'prune_weights',weight_threshold,'degree_threshold',degree_threshold,...
    'edge_features',{'sign',sign(df),'abs_weight',abs(df)},'force_edges',force_edges);


%%
% NOTE that the exported files can be loaded into cytoscape for further
% visualization.


function split_train_test_list(inclass_call_type, model_list_output_dir)

% Note: 
% Target & inclass mean the same thing 
% Non-target & outclass mean the same thing 

%% Directory structure & target call name 
train_test_split= 0.75; % 

Root_FMAM_Dir= fileparts(pwd);
mel_spectrogram_dir= [Root_FMAM_Dir filesep 'Mel_spect' filesep];

%% Read all call names and split into inclass/outclass groups 
rng(0); % set seed for reproducibility 

all_mel_spects= dir([mel_spectrogram_dir '**' filesep '*.mat']);
all_call_names= cellfun(@(x) extract_call_name(x), {all_mel_spects.folder}', 'UniformOutput',false);

inclass_indices= strcmpi(all_call_names, inclass_call_type);
outclass_indices= ~strcmpi(all_call_names, inclass_call_type);

inclass_melSGnames= all_mel_spects(inclass_indices);
inclass_melSGnames= cellfun(@(x,y) [x filesep y], {inclass_melSGnames.folder}', {inclass_melSGnames.name}', 'UniformOutput', false);

% nontarget = rest of the calls 
outclass_melSGnames= all_mel_spects(outclass_indices);
outclass_melSGnames= cellfun(@(x,y) [x filesep y], {outclass_melSGnames.folder}', {outclass_melSGnames.name}', 'UniformOutput', false);

outclass_melSGnames= randsample(outclass_melSGnames, numel(inclass_melSGnames)); % optional: to keep the same number of inclass and outclass calls 

inclass_melSGnames_train= randsample(inclass_melSGnames, round(train_test_split*numel(inclass_melSGnames)));
inclass_melSGnames_test= setdiff(inclass_melSGnames, inclass_melSGnames_train);
outclass_melSGnames_train= randsample(outclass_melSGnames, round(train_test_split*numel(outclass_melSGnames)));
outclass_melSGnames_test= setdiff(outclass_melSGnames, outclass_melSGnames_train);

%% Define output directory and filenames 

inclass_fName_fragments= sprintf('%sinclass_files_frag.txt', model_list_output_dir);
inclass_fName_train= sprintf('%sinclass_files_train.txt', model_list_output_dir);
outclass_fName_train= sprintf('%soutclass_files_train.txt', model_list_output_dir);
inclass_fName_test= sprintf('%sinclass_files_test.txt', model_list_output_dir);
outclass_fName_test= sprintf('%soutclass_files_test.txt', model_list_output_dir);

writetable(cell2table(inclass_melSGnames_train), inclass_fName_fragments, 'WriteVariableNames', false); % target call | for initial random feature generation (called fragments)
% If training and testing are done for clean calls (i.e., no degradation
% such as noise/reverberation, inclass_fName_train and inclass_fName_fragments can
% be identical. However, if model is trained in noisy/reverberant calls,
% then initial random features (fragments) should be sampled from clean
% calls alone. In that case, inclass_fName_fragments would point to clean
% calls, but inclass_fName_train can point to both clean and degraded calls. 
writetable(cell2table(inclass_melSGnames_train), inclass_fName_train, 'WriteVariableNames', false); % target call | training 
writetable(cell2table(outclass_melSGnames_train), outclass_fName_train, 'WriteVariableNames', false); % nontarget call | training 
writetable(cell2table(inclass_melSGnames_test), inclass_fName_test, 'WriteVariableNames', false); % target call | testing 
writetable(cell2table(outclass_melSGnames_test), outclass_fName_test, 'WriteVariableNames', false); % nontarget call | testing 

end

%% Functions 
function call_name= extract_call_name(dirName)
call_name= extractAfter(dirName, ['Mel_spect' filesep]);
end
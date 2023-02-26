function run_FB_auditory_model()
% function run_FB_auditory_model()
% Usage: train a feature-based model. 
% Set the variables in the "Initialize paramaters" section to select
% call/sound type and model parameters. 
%
% To choose a different mel-spectrogram folder (instead of the default
% 'Mel_spect' folder), update the variable dir_struct.mel_spectrogram_dir
% in the "Initialize directory structure" section.
% -----------------------------------------------------------------------
%   Copyright 2023 Satyabrata Parida, Shi Tong Liu, & Srivatsun Sadagopan

%% Initialize paramaters 
inclass_call_type= 'Purr'; % The model is trained to clasify inclass_call_type from the rest of the call types within the folder dir_struct.mel_spectrogram_dir

model_params= struct( ...
    'num_fragments', 200, ... % number of initial random features. The higher, the better (but could be resource intensive). A good ballpark number = ~5x-10x the number of (inclass + outclass) calls 
    'xcorr_routine', 'norm', ... % cross-correlation routine:  options: 'norm' (recommended), 'raw', 'bf_norm'
    'comp_routine', 'parfor', ... % computational routine: options: 'parfor' (recommended), 'gpu', 'for'
    'fs_Hz', 1000, ... % (temporal) sampling frequency of spectrogram/cochleagram 
    'num_MIFsets', 1, ... % How many instantiations of the model. Good to ensure convergence of the model. 
    'do_frag', 1, ... % whether to generate fragments or not, should be set to 1
    'do_greedy_search', 1, ... % whether to run serial greedy search or not, should be set to 1
    'do_test', 1, ... % set do_test and do_plot_test_roc to 0 to not test
    'do_plot_summary', 1); % set do_test and do_plot_test_roc to 0 to not test

%%  Initialize directory structure 
dir_struct.Root_FBAM_dir= fileparts(pwd); % Root folder 
dir_struct.mel_spectrogram_dir= [dir_struct.Root_FBAM_dir filesep 'Mel_spect' filesep]; % Folder that has the mel spectrograms, each subfolder should be different call/sound type 

%  Folders that will be created (if don't exist already)
dir_struct.Root_out_dir= [dir_struct.Root_FBAM_dir filesep 'Trained_models' filesep]; % Folder that has trained models 
dir_struct.FBAM_dir= sprintf('%s%s_vs_rest_FBAM_%s', dir_struct.Root_out_dir, inclass_call_type, model_params.xcorr_routine); % xcorr_routine should be in the name because a different model

% Check for existing FBAM_dir
count= dir([dir_struct.FBAM_dir '*']);
count= numel(count);
if count>0
    % means folder already exists
    temp_FBAM_dir= strrep(sprintf('%s_run%d', dir_struct.FBAM_dir, count), dir_struct.Root_out_dir, '');
    inp_str= input(sprintf('Output directory (%s) already exists. \nCreate new (n) or reuse the same (s) folder?', temp_FBAM_dir), 's');
    if strcmpi(inp_str, 'n')
        count= numel(count)+1;
    end
else  
    % first time 
    count= count+1;
end
dir_struct.FBAM_dir= sprintf('%s_run%d%s', dir_struct.FBAM_dir, count, filesep);

dir_struct.FBAM_list_dir= sprintf('%strain_test_list%s', dir_struct.FBAM_dir, filesep);

%% create training/testing lists 
train_test_split= 0.75;
max_calls_per_group= 50;
helper.split_train_test_list(inclass_call_type, dir_struct.mel_spectrogram_dir, dir_struct.FBAM_list_dir, max_calls_per_group, train_test_split); % create training and testing list by splitting all files 

%% Train FB model 
fbam.train_FB_auditory_model(inclass_call_type, dir_struct, model_params);

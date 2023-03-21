function run_FB_auditory_model(varargin)
% function run_FB_auditory_model()
% Usage: train a feature-based model.
% Set the variables in the "Initialize paramaters" section to select
% call/sound type and model parameters.
%
% Inputs: (all inputs are optional)
% If none [i.e., called as run_FB_auditory_model()]:
%   -> default inclass_call_type (target call type): 'Purr'
%   -> default model_params (FBAM parameters): (see below)
%   -> default dir_struct (directory structure): (see below)
%
%
% To set a different inclass (target) call type, use
% run_FB_auditory_model(..., 'inclass_call_type', inclass_call_type): where
%   -> inclass_call_type [string]: inclass call type (should be one of the folders in def_dir_struct.mel_spectrogram_dir [see below])
%
% To set different model parameters, use
% run_FB_auditory_model(..., 'model_params', model_params): where
%   -> model_params [structure]: should have all or some of the
%   following fields (default values following colon)
%       'num_fragments' [scalar]        : 200         -> number of initial random features. The higher, the better (but could be resource intensive). A good ballpark number = ~5x-10x the number of (inclass + outclass) calls
%       'xcorr_routine' [string]        : 'norm'      -> cross-correlation routine:  options: 'norm' (recommended), 'raw', 'bf_norm'
%       'comp_routine' [string]         : 'parfor'    -> computational routine: options: 'parfor' (recommended), 'gpu', 'for'
%       'fs_Hz' [scalar]                : 1000        -> (temporal) sampling frequency of spectrogram/cochleagram
%       'num_MIFsets' [scalar]          : 1           -> How many instantiations of the model. Good to ensure convergence of the model.
%       'do_frag' [scalar]              : 1           -> whether to generate fragments or not, should be set to 1
%       'do_greedy_search' [scalar]     : 1           -> whether to run serial greedy search or not, should be set to 1
%       'do_test' [scalar]              : 1           -> set do_test and do_plot_summary to 0 to not test
%       'do_plot_summary' [scalar]      : 1           -> set do_test and do_plot_summary to 0 to not test
%
% To set different directory structure, use
% run_FB_auditory_model(..., 'dir_struct', dir_struct): where
%   -> dir_struct [structure]: should have all or some of the
%   following fields (default values following colon)
%       'mel_spectrogram_dir' [string]  : '../Mel_spect/'           -> input mel-spectrogram dir
%       'Root_out_dir' [string]             : '../Trained_models/'  -> FBAM root output dir. Each model will be a subfolder inside this folder.
% -----------------------------------------------------------------------
%   Copyright 2023 Satyabrata Parida, Shi Tong Liu, & Srivatsun Sadagopan

%% Initialize paramaters
def_inclass_call_type= 'Purr'; % The model is trained to clasify inclass_call_type from the rest of the call types within the folder dir_struct.mel_spectrogram_dir

def_model_params= struct( ...
    'num_fragments', 200, ... % number of initial random features. The higher, the better (but could be resource intensive). A good ballpark number = ~5x-10x the number of (inclass + outclass) calls
    'xcorr_routine', 'norm', ... % cross-correlation routine:  options: 'norm' (recommended), 'raw', 'bf_norm'
    'comp_routine', 'parfor', ... % computational routine: options: 'parfor' (recommended), 'gpu', 'for'
    'fs_Hz', 1000, ... % (temporal) sampling frequency of spectrogram/cochleagram
    'num_MIFsets', 1, ... % How many instantiations of the model. Good to ensure convergence of the model.
    'do_frag', 1, ... % whether to generate fragments or not, should be set to 1
    'do_greedy_search', 1, ... % whether to run serial greedy search or not, should be set to 1
    'do_test', 1, ... % set do_test and do_plot_test_roc to 0 to not test
    'do_plot_summary', 1); % set do_test and do_plot_test_roc to 0 to not test

%  Initialize default directory structure
Root_FBAM_dir= fileparts(pwd); % Root folder
def_dir_struct.mel_spectrogram_dir= [Root_FBAM_dir filesep 'Mel_spect' filesep]; % Folder that has the mel spectrograms, each subfolder should be different call/sound type

%  Folders that will be created (if don't exist already)
def_dir_struct.Root_out_dir= [Root_FBAM_dir filesep 'Trained_models' filesep]; % Folder that has trained models

%% Parse inputs
fun_paramsIN=inputParser;
addParameter(fun_paramsIN, 'inclass_call_type', def_inclass_call_type, @ischar)
addParameter(fun_paramsIN, 'model_params', def_model_params, @isstruct)
addParameter(fun_paramsIN, 'dir_struct', def_dir_struct, @isstruct)
fun_paramsIN.KeepUnmatched= true;
parse(fun_paramsIN, varargin{:});

inclass_call_type= fun_paramsIN.Results.inclass_call_type;

% Look for missing fieldnames in model_params
model_params= fun_paramsIN.Results.model_params;
missing_fields= setdiff(fieldnames(def_model_params), fieldnames(model_params));
for fieldVar=1:length(missing_fields)
    model_params.(missing_fields{fieldVar})= def_model_params.(missing_fields{fieldVar});
end

dir_struct= fun_paramsIN.Results.dir_struct;

% Look for missing fieldnames in dir_struct
missing_fields= setdiff(fieldnames(def_dir_struct), fieldnames(dir_struct));
for fieldVar=1:length(missing_fields)
    dir_struct.(missing_fields{fieldVar})= def_dir_struct.(missing_fields{fieldVar});
end

%%
dir_struct.FBAM_dir= sprintf('%s%s_vs_rest_FBAM_%s', dir_struct.Root_out_dir, inclass_call_type, model_params.xcorr_routine); % xcorr_routine should be in the name because a different model
dir_struct = helper.bookkeep_dirstruct(dir_struct); 

%% create training/testing lists
train_test_split= 0.75;
max_calls_per_group= 50;
helper.split_train_test_list(inclass_call_type, dir_struct.mel_spectrogram_dir, dir_struct.FBAM_list_dir, max_calls_per_group, train_test_split); % create training and testing list by splitting all files

%% Train FB model
fbam.train_FB_auditory_model(inclass_call_type, dir_struct, model_params);

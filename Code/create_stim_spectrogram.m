function create_stim_spectrogram(varargin)
% function create_stim_spectrogram()
% Usage: To create mel-scaled spectrograms for each file (recursively)
% inside a Stimuli folder and save it in Mel_spect folder.
%
% Inputs: (all inputs are optional)
% If none [i.e., called as create_stim_spectrogram()]:
%   -> default input stimulus folder = '../Stimuli/'
%   -> default output spectrogram folder = '../mel_spectrogram_dir/'
%   -> default spectrogram parameters: (see below)
%   -> default verbose: true (for inloop printing)
%
% To set a different input stimulus folder, call
% create_stim_spectrogram(..., 'stim_dir', input_stim_dir): where
%   -> input_stim_dir [string]: path to root input stimulus folder
%
% To set a different output spectrogram folder, call
% create_stim_spectrogram(..., 'mel_spectrogram_dir', output_spectrogram_dir):
% where
%   -> output_spectrogram_dir [string]: path where output spectrograms will
%       be saved
%
% To use different spectrogram parameters, call
% create_stim_spectrogram(..., 'mel_spect_params', mel_spect_params):
% where
%   -> mel_spect_params [structure]: should have all or some of the
%   following fields (default values following colon)
%       'tWindow_s' [scalar]: 50e-3
%       'Fs_SG_Hz' [scalar]: 1e3
%       'FrequencyRange_Hz' [numeric array, size 2]: [80, 20e3]
%       'NumBands' [scalar]: 64
%       'level_dBSPL' [scalar]: 65
%
% To suppress in-loop printing on command line, use create_stim_spectrogram(...,
% 'verbose', false).
%
% Output: None
%
% -----------------------------------------------------------------------
%   Copyright 2023 Satyabrata Parida, Shi Tong Liu, & Srivatsun Sadagopan

%% Parse input

% Default directory structure.
Root_FBAM_Dir= fileparts(pwd);
def_stim_dir= [Root_FBAM_Dir filesep 'Stimuli' filesep]; % Default stimuli root folder
def_mel_spectrogram_dir= [Root_FBAM_Dir filesep 'Mel_spect' filesep]; % Default spectrogram root folder
def_mel_spect_params= struct('tWindow_s', 50e-3, 'Fs_SG_Hz', 1e3, 'FrequencyRange_Hz', [80, 20e3], 'NumBands', 64, 'level_dBSPL', 65); % Default spectrogram parameters

% Parse inputs
fun_paramsIN=inputParser;
default_params= struct('stim_dir', def_stim_dir, 'mel_spectrogram_dir', def_mel_spectrogram_dir, 'verbose', true, 'mel_spect_params', def_mel_spect_params, 'comp_routine', 'parfor');
addParameter(fun_paramsIN, 'stim_dir', default_params.stim_dir, @ischar)
addParameter(fun_paramsIN, 'mel_spectrogram_dir', default_params.mel_spectrogram_dir, @ischar)
addParameter(fun_paramsIN, 'mel_spect_params', default_params.mel_spect_params, @isstruct)
addParameter(fun_paramsIN, 'comp_routine', default_params.comp_routine, @ischar)
addParameter(fun_paramsIN, 'verbose', default_params.verbose, @islogical)
fun_paramsIN.KeepUnmatched= true;
parse(fun_paramsIN, varargin{:});

% Look for missing fieldnames in mel_spect_params
mel_spect_params= fun_paramsIN.Results.mel_spect_params;
missing_fields= setdiff(fieldnames(def_mel_spect_params), fieldnames(mel_spect_params));
for fieldVar=1:length(missing_fields)
    mel_spect_params.(missing_fields{fieldVar})= def_mel_spect_params.(missing_fields{fieldVar});
end

%% Read stimuli
all_sound_files= dir([fun_paramsIN.Results.stim_dir '**' filesep '*.*']);
valid_ext= {'.wav', '.mp3', 'flac', '.m4a', '.mp4', '.ogg', '.oga', '.opus'};
valid_file_inds= cellfun(@(x) any(contains(x, valid_ext)), {all_sound_files.name}');
all_sound_files= all_sound_files(valid_file_inds);

% Check how many stimuli were found
if numel(all_sound_files)==0
    fprintf('Did not find any sound files inside %s\n', fun_paramsIN.Results.stim_dir)
elseif numel(all_sound_files)>0
    fprintf('Found %d sound files, Creating mel-scaled spectrograms now\n', numel(all_sound_files))
end

%% Make sure directory names are absolute
stim_dir= helper.GetFullPath(fun_paramsIN.Results.stim_dir);
mel_spectrogram_dir= helper.GetFullPath(fun_paramsIN.Results.mel_spectrogram_dir);

%% figure out xcorr_routine and parallel computing options
comp_routine= fun_paramsIN.Results.comp_routine;
if strcmp(fun_paramsIN.Results.comp_routine, 'parfor')
    if ~license('test','Distrib_Computing_Toolbox')
        comp_routine= 'for';
    end
end
%% Main loop to get/create spectrograms
already_exist_array= zeros(length(all_sound_files), 1);

switch comp_routine
    case 'parfor'

        parfor fileVar=1:length(all_sound_files)
            already_exist_array(fileVar)= sg_routine(fileVar, all_sound_files, stim_dir, mel_spectrogram_dir, mel_spect_params, fun_paramsIN);
        end

    otherwise % should be for 

        for fileVar=1:length(all_sound_files)
            already_exist_array(fileVar)= sg_routine(fileVar, all_sound_files, stim_dir, mel_spectrogram_dir, mel_spect_params, fun_paramsIN);
        end
end

if fun_paramsIN.Results.verbose
    fprintf('--------\n--------\n--------\n');
end

already_exist_count= sum(already_exist_array);
fprintf('Done. %d files already existed and saved %d new files.\n', already_exist_count, length(all_sound_files)-already_exist_count)
end



%% Sub-functions
function [mel_S_dB, mel_freq_Hz, mel_time, mel_spect_params]= get_mel_spect(stim, fs_Hz, mel_spect_params)
mel_spect_params.frac_overlap= 1 - 1/(mel_spect_params.tWindow_s * mel_spect_params.Fs_SG_Hz);
stim= rescale_sig(stim, mel_spect_params.level_dBSPL);
mel_window= hamming(round(mel_spect_params.tWindow_s*fs_Hz));
mel_overlap_len= round(mel_spect_params.tWindow_s*fs_Hz*mel_spect_params.frac_overlap);
FrequencyRange_Hz= min(fs_Hz/2, mel_spect_params.FrequencyRange_Hz);

[S_mag,mel_freq_Hz,mel_time] = melSpectrogram(stim, fs_Hz, "Window", mel_window, "OverlapLength", mel_overlap_len, "FrequencyRange", FrequencyRange_Hz, "NumBands", mel_spect_params.NumBands);
mel_S_dB= pow2db(S_mag);
end

function vecOut= rescale_sig(vecIn, newSPL, verbose)

if ~exist('verbose', 'var')
    verbose=0;
end

if ~ismember(size(vecIn,2), [1,2])
    error('signal should be a one or two column matrix');
end

pRef= 20e-6; % for re. dB SPl
vecOut= nan(size(vecIn));
for chanVar= 1:size(vecIn, 2)
    if any(vecIn(:,chanVar))
        oldSPL= 20*log10(rms(vecIn(:,chanVar))/pRef);
        gainVal= 10^( (newSPL-oldSPL)/20 );
    else
        gainVal =0;
    end
    vecOut(:,chanVar)= vecIn(:,chanVar)*gainVal;
end

if verbose
    fprintf('Signal RMS= %.1f (Desired %.1f) \n', 20*log10(rms(vecOut)/pRef), newSPL);
end
end

function plot_mel_spectrogram(mel_time, mel_freq_Hz, mel_S_dB, cur_fStruct)
figSize_cm= [3 3 18.3 9];
figure_prop_name = {'PaperPositionMode','units','Position', 'Renderer'};
figure_prop_val =  { 'auto'            ,'centimeters', figSize_cm, 'painters'};  % [Xcorner Ycorner Xwidth Ywidth]
figure(2);
clf;
set(gcf,figure_prop_name,figure_prop_val);

imagesc(mel_time, mel_freq_Hz/1e3, mel_S_dB)
set(gca, 'YScale', 'log', 'YDir', 'normal', 'YTick', [.2, .5, 1, 2, 4, 8, 16], 'TickDir', 'both', 'Box', 'off', 'Position', [.08, .15, .9, .78], 'Units', 'normalized');
xlabel('Time (s)')
ylabel('Freq, kHz')
title(sprintf('MelSpect: %s', cur_fStruct.name), 'Interpreter','none')
end

function flag_already_exist= sg_routine(fileVar, all_sound_files, stim_dir, mel_spectrogram_dir, mel_spect_params, fun_paramsIN)

doPlot= 0;
doSave= 1;

% read the audio file
cur_fStruct= all_sound_files(fileVar);
cur_fName_in= [cur_fStruct.folder filesep cur_fStruct.name];
[~,~,stim_ext]= fileparts(cur_fName_in);

cur_fName_out= strrep(cur_fName_in, stim_dir, mel_spectrogram_dir);
cur_fName_out= strrep(cur_fName_out, stim_ext, '.mat');

if ~exist(cur_fName_out, 'file')
    [cur_stim, fs_stim]= audioread(cur_fName_in);

    % get mel spectrogram
    [mel_S_dB,mel_freq_Hz, mel_time, mel_spect_params]= get_mel_spect(cur_stim, fs_stim, mel_spect_params);

    % plot spectrogram
    if doPlot
        plot_mel_spectrogram(mel_time, mel_freq_Hz, mel_S_dB, cur_fStruct);
    end

    % save spectrogram
    if doSave
        if ~isfolder(fileparts(cur_fName_out))
            mkdir(fileparts(cur_fName_out));
        end
        mel_spectrogram_struct= struct('mel_S_dB', mel_S_dB, 'mel_freq_Hz', mel_freq_Hz, 'stim_filename', cur_fName_in, 'mel_spect_params', mel_spect_params);
        save(cur_fName_out, 'mel_spectrogram_struct');
    end
    if fun_paramsIN.Results.verbose
        fprintf('-> %d/%d: Saved spectrogram %s for stimulus %s! \n', fileVar, length(all_sound_files), cur_fName_in, cur_fName_out);
    end
    flag_already_exist= 0;
else
    if fun_paramsIN.Results.verbose
        fprintf('(Already exists) %d/%d: Spectrogram %s for stimulus %s! \n', fileVar, length(all_sound_files), cur_fName_in, cur_fName_out);
    end
    flag_already_exist= 1;
end
end
clear;
clc;

Root_FMAM_Dir= fileparts(pwd);
stim_dir= [Root_FMAM_Dir filesep 'Stimuli' filesep];
mel_spectrogram_dir= [Root_FMAM_Dir filesep 'Mel_spect' filesep];

doPlot= 0;
doSave= 1;

all_sound_files= dir([stim_dir '**' filesep '*.wav']);
mel_spect_params= struct('tWindow_s', 50e-3, 'Fs_SG_Hz', 1e3, 'FrequencyRange_Hz', [80, 20e3], 'NumBands', 64, 'level_dBSPL', 65);

for fileVar=1:length(all_sound_files)
    
    %% read audio file
    cur_fStruct= all_sound_files(fileVar);
    cur_fName_in= [cur_fStruct.folder filesep cur_fStruct.name];

    [cur_stim, fs_stim]= audioread(cur_fName_in);

    %% get mel spectrogram
    [mel_S_dB,mel_freq_Hz,mel_time, mel_spect_params]= get_mel_spect(cur_stim, fs_stim, mel_spect_params);

    %% plot spectrogram
    if doPlot
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

    %% save spectrogram
    if doSave
        cur_fName_out= strrep(cur_fName_in, stim_dir, mel_spectrogram_dir);
        cur_fName_out= strrep(cur_fName_out, '.wav', '.mat');
        if ~isfolder(fileparts(cur_fName_out))
            mkdir(fileparts(cur_fName_out));
        end
        mel_spectrogram_struct= struct('mel_S_dB', mel_S_dB, 'mel_freq_Hz', mel_freq_Hz, 'stim_filename', cur_fName_in, 'mel_spect_params', mel_spect_params);
        save(cur_fName_out, 'mel_spectrogram_struct');
    end
end




%% functions
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
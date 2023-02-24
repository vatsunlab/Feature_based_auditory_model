function generate_fragments(spect_files, FragFiles, fs_Hz, durMax)
% function generate_fragments(spect_files, FragFiles, fs_Hz, durMax)
% Usage: Randomly generate fragments from spectrograms/cochleagram and save
%   those fragments
% Inputs:
%   1. spect_files [cell array]: Call spectrogram filenames
%   2. FragFiles [cell array]: Random feature (fragment) filenames to save
%   3. fs_Hz [scalar]: sampling frequency to use for FragFiles (can be
%       different from the fs for spect_files)
%   4. template [2D matrix]: the template (i.e., the spectrotemporal receptive field
%       of a feature)
%   5. durMax [scalar]: if features should be time constrained
% Output: None
%
% -----------------------------------------------------------------------
%   Copyright 2023 Satyabrata Parida, Shi Tong Liu, & Srivatsun Sadagopan

%%
% CHECK INPUT TPYE
if ~iscell(spect_files) || ~iscell(FragFiles)
    error('Input Type Not Valid')
end

if ~exist('durMax', 'var')
    dur_ind_max= inf;
else
    dur_ind_max= round(durMax*fs_Hz);
end

just_frag_names= cell(numel(FragFiles), 1);
for fragVar=1:numel(FragFiles)
    [frag_root_dir, just_frag_names{fragVar}]= fileparts(FragFiles{fragVar});
end
already_saved_frags= dir([frag_root_dir filesep '*.mat']);

if numel(already_saved_frags)~=numel(FragFiles) % go through the loop only if all fragments are not saved already

    fprintf('Generating fragments...\n');
    print_handle= 0;
    FragInds= cellfun(@(x) sscanf(x, 'frag%d'), just_frag_names);

    for fragVar= 1:numel(FragFiles)
        % PICK RANDOM COCHLEAGRAM WITH REPLACEMENT
        n= datasample(1:numel(spect_files),1);
        file2load= strrep(spect_files{n}, '\', filesep);
        mel_spectrogram_struct= load(file2load);
        mel_spectrogram_struct= mel_spectrogram_struct.mel_spectrogram_struct;

        CF_Hz= mel_spectrogram_struct.mel_freq_Hz;
        mel_spectrogram_data= mel_spectrogram_struct.mel_S_dB;

        %     Fs= 10e3;
        Fs_org= mel_spectrogram_struct.mel_spect_params.Fs_SG_Hz;
        mel_spectrogram_data= resample(mel_spectrogram_data', fs_Hz, Fs_org)';
        T= (1:size(mel_spectrogram_data,2))/fs_Hz;  % time vector

        % PICK RANDOM FREQUENCY RANGE (Bandwidth is the free variable)
        [iFlo,iFhi]= randBW(CF_Hz);
        % PICK RANDOM TEMPORAL DURATION (Duration is the free variable)
        [iT1,iT2]= randDUR(T, dur_ind_max);
        % extract fragment
        data= mel_spectrogram_data(iFlo:iFhi, iT1:iT2);

        % SAVE RESULTS
        % convert from indices to numeric values
        Flo_Hz= CF_Hz(iFlo);  % lower freq, in same unit as freq vector
        Fhi_Hz= CF_Hz(iFhi);  % upper freq, in same unit as freq vector
        %     CF= (Fhi-Flo)/2;  % center freq, in same unit as freq vector
        CF_Hz= sqrt(Fhi_Hz*Flo_Hz);  % center freq, in same unit as freq vector
        BW_octave= log2(Fhi_Hz/Flo_Hz);  % bandwidth, in octaves
        T1_sec= T(iT1);  % lower freq, in same unit as time vector
        T2_sec= T(iT2);  % upper freq, in same unit as time vector
        DUR_sec= T2_sec-T1_sec;  % temporal duration, in same unit as time vector

        % save data structure
        frag.fragindex= FragInds(fragVar);
        frag.parentfile= spect_files{n,:};
        frag.strf= data; % spectro-temporal receptive field
        frag.fs_Hz= fs_Hz;
        frag.freqlower_Hz= Flo_Hz;
        frag.frequpper_Hz= Fhi_Hz;
        frag.centerfreq_Hz= CF_Hz;
        frag.bandwidth_octave= BW_octave;
        frag.timestart_sec= T1_sec;
        frag.timestop_sec= T2_sec;
        frag.duration_sec= DUR_sec;

        if ~exist(FragFiles{fragVar}, 'file')
            save(FragFiles{fragVar},'frag');  %save fragment
        end

        if rem(fragVar, 10)==0
            fprintf(repmat('\b', 1, print_handle))
            print_handle= fprintf('   -> %.0f%% done %d/%d fragments', 100*fragVar/numel(FragFiles), fragVar, numel(FragFiles));
        end

    end

    fprintf('\nDone generating fragments!! \n......................................\n \n')

else 
    fprintf('Fragments have already been generated for this model! \n');
end

% SUB FUNCTIONS
%--------------------------------------------------------------------------
function [iFlo,iFhi]= randBW(Freq_Hz)
% PICK RANDOM BANDWIDTH
BWlb= 1;
BWub= numel(Freq_Hz)-1;  %lower and upper bound of bandwidth, in indices
iBW= datasample(BWlb:BWub,1);  % pick random bandwidth, in indices
% PICK RANDOM LOWER FREQ, AND CALCULATE UPPER FREQ
iFlo= datasample(1:numel(Freq_Hz)-iBW,1);  % lower freq, in indices
iFhi= iFlo+iBW;  % upper freq, in indices

function [iT1,iT2]= randDUR(T_sec, dur_ind_max)
% PICK RANDOM DURATION
DURlb= 1;
DURub= numel(T_sec)-1;  %lower and upper bound of duration, in indices
iDUR= datasample(DURlb:min(dur_ind_max, DURub),1);  % pick random duration, in indices
% PICK RANDOM LOWER FREQ, AND CALCULATE UPPER FREQ
iT1= datasample(1:numel(T_sec)-iDUR,1);  % starting time, in indices
iT2= iT1+iDUR;  % end time, in indices

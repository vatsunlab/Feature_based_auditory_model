function generate_fragments(spect_files, FragFiles, fs_Hz, durMax)
% RUNFRAGGENAN Randomly generates fragments of cochleagram
%   RUNFRAGGENAN(COGFILES,FRAGFILES,FRAGIND) generate fragment files from
%   cochleagrams specified by COGFILES and save under directories specified
%   by FRAGFILES. FRAGIND is used to indexing the fragments. Both COGFILES
%   and FRAGFILES must be cell arrays, and FRAGIND must be numeric array
%
% fragFiles should be the full list so that random number generator works consistently. 
% fragInds2save indicates which fragFiles to actually save
%   CALLED FUNCTIONS: N/A


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
    [~, just_frag_names{fragVar}]= fileparts(FragFiles{fragVar});
end


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
    Flo= CF_Hz(iFlo);  % lower freq, in same unit as freq vector
    Fhi= CF_Hz(iFhi);  % upper freq, in same unit as freq vector
    %     CF= (Fhi-Flo)/2;  % center freq, in same unit as freq vector
    CF= sqrt(Fhi*Flo);  % center freq, in same unit as freq vector
    BW= log2(Fhi/Flo);  % bandwidth, in octaves
    T1= T(iT1);  % lower freq, in same unit as time vector
    T2= T(iT2);  % upper freq, in same unit as time vector
    DUR= T2-T1;  % temporal duration, in same unit as time vector
    
    % save data structure
    frag.fragindex= FragInds(fragVar);
    frag.parentfile= spect_files{n,:};
    frag.data= data;
    frag.Fs= fs_Hz;
    frag.freqlower= Flo;
    frag.frequpper= Fhi;
    frag.centerfreq= CF;
    frag.bandwidth= BW;
    frag.timestart= T1;
    frag.timestop= T2;
    frag.duration= DUR;
    
    if ~exist(FragFiles{fragVar}, 'file')
        save(FragFiles{fragVar},'frag');  %save fragment
    end
end

% SUB FUNCTIONS
%--------------------------------------------------------------------------
function [iFlo,iFhi]= randBW(F)
% PICK RANDOM BANDWIDTH
BWlb= 1;  
BWub= numel(F)-1;  %lower and upper bound of bandwidth, in indices
iBW= datasample(BWlb:BWub,1);  % pick random bandwidth, in indices
% PICK RANDOM LOWER FREQ, AND CALCULATE UPPER FREQ
iFlo= datasample(1:numel(F)-iBW,1);  % lower freq, in indices
iFhi= iFlo+iBW;  % upper freq, in indices


function [iT1,iT2]= randDUR(T, dur_ind_max)
% PICK RANDOM DURATION
DURlb= 1;  
DURub= numel(T)-1;  %lower and upper bound of duration, in indices
iDUR= datasample(DURlb:min(dur_ind_max, DURub),1);  % pick random duration, in indices
% PICK RANDOM LOWER FREQ, AND CALCULATE UPPER FREQ
iT1= datasample(1:numel(T)-iDUR,1);  % starting time, in indices
iT2= iT1+iDUR;  % end time, in indices

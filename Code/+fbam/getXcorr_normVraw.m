function corr_values = getXcorr_normVraw(Calls, Flo_Hz, Fhi_Hz, template, fs_Hz, varargin)
% function corr_values = getXcorr_normVraw(Calls, Flo_Hz, Fhi_Hz, template, fs_Hz, varargin)
% Usage: compute and return cross-correlation of TEMPLATE with CALLS, bounded in frequency between Flo_Hz and Fhi_Hz.
% Inputs:
%   1. Calls [cell array]: Call spectrogram filenames 
%   2. Flo_Hz [scalar]: Lower frequency bound of the template
%   3. Fhi_Hz [scalar]: Upper frequency bound of the template
%   4. template [2D matrix]: the template (i.e., the spectrotemporal receptive field
%       of a feature)
%   5. fs_Hz [scalar]: template sampling frequency (fs). If call fs is different
%       from template fs, then call spectrograms are resampled to match
%       template fs.
%   (optional) paired inputs
%       a. 'comp_routine": {'for' (default), 'parfor', 'gpu'} |
%           Computational routine -> choose either regular for-loop, or
%           parallel for-loop, or gpu (if available) to speed up
%           computation time 
%       b. 'xcorr_routine": {'norm' (default), 'raw', 'bf_norm'} |
%           Correlation routine -> use normalized (contrast-gain control)
%           correlation, or raw (just demeaned, no contrast change)
%           correlation, or bio-feasible normalization
% Output:
%   1. corr_values [array]: max correlation values for all calls (same size
%       as calls)
% 
% -----------------------------------------------------------------------
%   Copyright 2023 Satyabrata Parida, Shi Tong Liu, & Srivatsun Sadagopan

%% Parse input
fun_paramsIN=inputParser;

default_params= struct('comp_routine', 'for', 'xcorr_routine', 'norm');
addRequired(fun_paramsIN, 'Calls', @iscell);
addRequired(fun_paramsIN, 'Flo_Hz', @isnumeric);
addRequired(fun_paramsIN, 'Fhi_Hz', @isnumeric);
addRequired(fun_paramsIN, 'template', @isnumeric);
addRequired(fun_paramsIN, 'fs_Hz', @isnumeric);

addParameter(fun_paramsIN,'comp_routine', default_params.comp_routine, @ischar)
addParameter(fun_paramsIN,'xcorr_routine', default_params.xcorr_routine, @ischar)

fun_paramsIN.KeepUnmatched= true;
parse(fun_paramsIN, Calls, Flo_Hz, Fhi_Hz, template, fs_Hz, varargin{:});

%%
if any(strcmp(fun_paramsIN.Results.xcorr_routine, {'raw', 'bf_norm'})) % use call cog as is, normalize template
    template= template - mean(template(:));
    template= template/sum(template(:).^2);
end

if strcmp(fun_paramsIN.Results.comp_routine, 'gpu')
    reset(gpuDevice)
    template_GPU= gpuArray(template);  % transfer to GPU
end

%%
corr_values= nan(1,size(Calls,1));	% initialize
% max_corr_inds= nan(1,size(Calls,1));	% initialize

switch fun_paramsIN.Results.comp_routine
    case {'for', 'gpu'}

        for call_iter= 1:numel(Calls)
            mel_spectrogram_struct= load(Calls{call_iter});
            mel_spectrogram_struct= mel_spectrogram_struct.mel_spectrogram_struct;

            % INPUT CALL IS COCHLEAGRAM
            call_cog_mr= mel_spectrogram_struct.mel_S_dB;
            minus_inf_inds= isinf(call_cog_mr) & (call_cog_mr<0);
            call_cog_mr(minus_inf_inds)= min(min(call_cog_mr(~minus_inf_inds)));

            if fs_Hz~=mel_spectrogram_struct.mel_spect_params.Fs_SG_Hz
                call_cog_mr= resample(call_cog_mr', fs_Hz, mel_spectrogram_struct.mel_spect_params.Fs_SG_Hz)';
            end

            [~,Freq_min_ind] = min(abs(mel_spectrogram_struct.mel_freq_Hz - Flo_Hz));  % change absolute value to index
            [~,Freq_max_ind] = min(abs(mel_spectrogram_struct.mel_freq_Hz - Fhi_Hz));
            call_cog_mr = call_cog_mr(Freq_min_ind:Freq_max_ind,:);  % extract relavent freq range
            %A = A(Flo_Hz:Fhi_Hz,:);

            % check if call size is valid
            if size(call_cog_mr,2)<size(template,2)
                call_cog_mr= [call_cog_mr, zeros(size(call_cog_mr,1), size(template,2) - size(call_cog_mr,2))];   % add zero if call < template
            end

            if strcmp(fun_paramsIN.Results.comp_routine, 'gpu')
                
                if strcmp(fun_paramsIN.Results.xcorr_routine, 'raw')
                    call_cog_mr_GPU= gpuArray(call_cog_mr);  % transfer to GPU
                    ccf_call_template = gather(xcorr2(call_cog_mr_GPU, template_GPU));

                elseif strcmp(fun_paramsIN.Results.xcorr_routine, 'bf_norm')
                    call_cog_mr= (call_cog_mr-mean(call_cog_mr(:)))/std(call_cog_mr(:));
                    call_cog_mr_GPU= gpuArray(call_cog_mr);  % transfer to GPU
                    ccf_call_template = gather(xcorr2(call_cog_mr_GPU, template_GPU));

                elseif strcmp(fun_paramsIN.Results.xcorr_routine, 'norm')
                    call_cog_mr_GPU= gpuArray(call_cog_mr);  % transfer to GPU
                    ccf_call_template = gather(normxcorr2(template_GPU, call_cog_mr_GPU));

                else
                    error('No option %s for xcorr_routine', fun_paramsIN.Results.xcorr_routine);
                end

                clear call_cog_mr_GPU;

            elseif strcmp(fun_paramsIN.Results.comp_routine, 'for') % no gpu
                
                if strcmp(fun_paramsIN.Results.xcorr_routine, 'raw')
                    ccf_call_template= xcorr2(call_cog_mr, template);

                elseif strcmp(fun_paramsIN.Results.xcorr_routine, 'bf_norm')
                    call_cog_mr= (call_cog_mr-mean(call_cog_mr(:)))/std(call_cog_mr(:));
                    ccf_call_template = xcorr2(call_cog_mr, template);

                elseif strcmp(fun_paramsIN.Results.xcorr_routine, 'norm')
                    ccf_call_template = normxcorr2(template, call_cog_mr);

                else
                    error('No option %s for xcorr_routine', fun_paramsIN.Results.xcorr_routine);
                end
            end

            % extract correlation values only when template is fully overlapped with the matrix A
            ccf_full_ovlap= ccf_call_template(size(template,1):size(call_cog_mr,1),size(template,2):size(call_cog_mr, 2));
            [corr_values(call_iter), max_corr_inds(call_iter)] = max(ccf_full_ovlap);  % maximum normalized cross correlation
        end

    case  'parfor'
        parfor call_iter= 1:numel(Calls)
            %     for callIter= 1:numel(Calls) % for debugging
            mel_spectrogram_struct= load(Calls{call_iter});
            mel_spectrogram_struct= mel_spectrogram_struct.mel_spectrogram_struct;

            call_cog_mr= mel_spectrogram_struct.mel_S_dB;
            minus_inf_inds= isinf(call_cog_mr) & (call_cog_mr<0);
            call_cog_mr(minus_inf_inds)= min(min(call_cog_mr(~minus_inf_inds)));

            if fs_Hz~=mel_spectrogram_struct.mel_spect_params.Fs_SG_Hz
                call_cog_mr= resample(call_cog_mr', fs_Hz, mel_spectrogram_struct.mel_spect_params.Fs_SG_Hz)';
            end

            if all(~isnan(call_cog_mr(:)))

                [~,Freq_min_ind] = min(abs(mel_spectrogram_struct.mel_freq_Hz - Flo_Hz));  % change absolute value to index
                [~,Freq_max_ind] = min(abs(mel_spectrogram_struct.mel_freq_Hz - Fhi_Hz));
                call_cog_mr = call_cog_mr(Freq_min_ind:Freq_max_ind,:);  % extract relavent freq range

                % check if call size is valid
                if size(call_cog_mr,2)<size(template,2)
                    call_cog_mr= [call_cog_mr, zeros(size(call_cog_mr,1), size(template,2) - size(call_cog_mr,2))];   % add zero if call < template
                end

                if strcmp(fun_paramsIN.Results.xcorr_routine, 'raw')
                    ccf_call_template= xcorr2(call_cog_mr, template);

                elseif strcmp(fun_paramsIN.Results.xcorr_routine, 'bf_norm')
                    call_cog_mr= (call_cog_mr-mean(call_cog_mr(:)))/std(call_cog_mr(:));
                    ccf_call_template = xcorr2(call_cog_mr, template);

                elseif strcmp(fun_paramsIN.Results.xcorr_routine, 'norm')
                    ccf_call_template = normxcorr2(template, call_cog_mr);

                else
                    error('No option %s for xcorr_routine', fun_paramsIN.Results.xcorr_routine);
                end

                % extract correlation values only when template is fully overlapped with the matrix A
                ccf_full_ovlap= ccf_call_template(size(template,1):size(call_cog_mr,1), size(template,2):size(call_cog_mr, 2));
                %                 [corr_values(callIter), max_corr_inds(callIter)] = max(ccf_full_ovlap);  % maximum normalized cross correlation
                corr_values(call_iter)= max(ccf_full_ovlap);  % maximum normalized cross correlation

            else
                corr_values(call_iter)= nan;
                %                 max_corr_inds(callIter)= nan;
            end
        end
end
end
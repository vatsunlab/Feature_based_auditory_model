function runFeatXcorr_Analysis(fragFiles, featFiles, calls_inclass, calls_outclass, varargin)
% function runFeatXcorr_Analysis(fragFiles, featFiles, calls_inclass, calls_outclass, varargin)
% Usage: (1) Calculate inclass and outclass correlation values for each random
%   feature (i.e., fragment), (2) estimate threshold, merit, and weight of
%   each feature based on the correlation values, (3) save those data 
% Inputs: 
%   1. fragFiles [cell array]: names of random features (fragments) to load 
%   2. featFiles [cell array]: names of features to save after estimating
%       correlation, threshold, merit, and weight 
%   3. calls_inclass [cell array]: names of inclass call spectrograms 
%   4. calls_outclass [cell array]: names of outclass call spectrograms 
%   (optional) paired inputs
%       a. 'comp_routine": {'for' (default), 'parfor', 'gpu'} |
%           Computational routine -> choose either regular for-loop, or
%           parallel for-loop, or gpu (if available) to speed up
%           computation time 
%       b. 'xcorr_routine": {'norm' (default), 'raw', 'bf_norm'} |
%           Correlation routine -> use normalized (contrast-gain control)
%           correlation, or raw (just demeaned, no contrast change)
%           correlation, or bio-feasible normalization
% Output: None 
% 
% -----------------------------------------------------------------------
%   Copyright 2023 Satyabrata Parida, Shi Tong Liu, & Srivatsun Sadagopan

%% CHECK INPUT TPYE
if ~iscell(fragFiles) || ~iscell(featFiles) || ~iscell(calls_inclass) || ~iscell(calls_outclass)
    error('Input Type Not Valid')
end

%% Parse input
fun_paramsIN=inputParser;

default_params= struct('comp_routine', 'for', 'xcorr_routine', 'norm');
addRequired(fun_paramsIN, 'fragFiles', @iscell);
addRequired(fun_paramsIN, 'featFiles', @iscell);
addRequired(fun_paramsIN, 'calls_inclass', @iscell);
addRequired(fun_paramsIN, 'calls_outclass', @iscell);

addParameter(fun_paramsIN,'comp_routine', default_params.comp_routine, @ischar)
addParameter(fun_paramsIN,'xcorr_routine', default_params.xcorr_routine, @ischar)

fun_paramsIN.KeepUnmatched= true;
parse(fun_paramsIN, fragFiles, featFiles, calls_inclass, calls_outclass, varargin{:});

%% COMPUTE CROSS-CORRELATION
fprintf('Computing threshold and weight of features...\n');
print_handle= 0;
for fragVar = 1:numel(fragFiles)
    if ~exist(featFiles{fragVar}, 'file')

        [template, Flo_Hz, Fhi_Hz, fragInd, fs_Hz] = pfLoadFrag(fragFiles{fragVar});

        if max(abs(template(:)))>eps  % weird error for some wheeks
            % calculate feature correlation values for inclass and outclass calls
            corr_inclass = fbam.getXcorr_normVraw(calls_inclass, Flo_Hz, Fhi_Hz, template, fs_Hz, 'comp_routine', fun_paramsIN.Results.comp_routine, 'xcorr_routine', fun_paramsIN.Results.xcorr_routine);
            corr_outclass = fbam.getXcorr_normVraw(calls_outclass, Flo_Hz, Fhi_Hz, template, fs_Hz, 'comp_routine', fun_paramsIN.Results.comp_routine, 'xcorr_routine', fun_paramsIN.Results.xcorr_routine);
        else
            corr_inclass= nan; % weird error for some wheeks
            corr_outclass= nan; % weird error for some wheeks
        end

        runFeatAna_Save(featFiles{fragVar}, corr_inclass, corr_outclass, fragInd, fragFiles{fragVar}, fs_Hz);
    end

    if rem(fragVar, 10)==0
        fprintf(repmat('\b', 1, print_handle))
        print_handle= fprintf('   -> %.0f%% done %d/%d features done', 100*fragVar/numel(fragFiles), fragVar, numel(fragFiles));
    end
    
end

fprintf('\nDone computing threshold and weight of features!! \n......................................\n')
end

% SUB FUNCTIONS
%--------------------------------------------------------------------------
function [template, Flo, Fhi,fragInd,fs_Hz] = pfLoadFrag(fragfile)
load(fragfile,'frag')
template = frag.strf;
Flo = frag.freqlower_Hz;
Fhi = frag.frequpper_Hz;
fragInd = frag.fragindex;
fs_Hz= frag.fs_Hz;
end

function runFeatAna_Save(featFile, corr_inclass, corr_outclass, fragInd, fragFile, fs_Hz)
%RUNFEATANA Optimal threshold & merit of feature
%   RUNFEATANA(FEATFILES) computes optimal merit and threshold of
%   the feature files specified by FEATFILES. The results are automatically
%   added to the feature struct. FEATFILES must be a cell array.
%
%   CALLED FUNCTIONS: getMerit, getWeight

% COMPUTE OPTIMAL THRESHOLD & MERIT (NO OTHER OPTION SELECTED)
feat.featindex = fragInd;
feat.fragfile = fragFile;
feat.inclasscorr = corr_inclass;
feat.outclasscorr = corr_outclass;
feat.fs_Hz= fs_Hz;

% use 100 point vector to find optimal threshold
theta_prc = prctile(feat.inclasscorr(:),1:1:100);
theta_ln = linspace(min(feat.inclasscorr),max(feat.inclasscorr),100);
T = sort([theta_prc,theta_ln],'ascend');
theta = unique(round(T,4));

M = zeros(1,numel(theta));
for z = 1:numel(theta)
    detect1 = feat.inclasscorr>=theta(z);
    detect2 = feat.outclasscorr>=theta(z);

    M(z) = fbam.getMerit(detect1,detect2);
end
[merit, indx1] = max(M);
% Since there maybe a range of threshold values that gives maximum
% merit, for robust recognition, chooses middle of threshold range
I = find(M==merit);  % find all indices of max merit
% determine if there is a continuous range of indices
if numel(I)>1
    dI_c = find(diff(I)==1);
    if ~isempty(dI_c)
        indx = I(ceil(numel(dI_c)/2));
    else
        indx= I(1);
    end
    threshold = theta(indx);

else
    threshold = theta(indx1);
end

tvsm= [theta;M];
% COMPUTE WEIGHT
weight = fbam.getWeight(feat.inclasscorr>=threshold,...
    feat.outclasscorr>=threshold,...
    feat.inclasscorr<threshold,...
    feat.outclasscorr<threshold);

% UPDATE FEAT STRUCT
feat.tvsm = tvsm;
feat.thresh_opt = threshold;
feat.merit_opt = merit;
% add working threshold and merit if none existing
if ~isfield('feat','thresh')
    feat.thresh = threshold;
end
if ~isfield('feat','merit')
    feat.merit = merit;
end
feat.weight = weight;
save(featFile,'feat')
end
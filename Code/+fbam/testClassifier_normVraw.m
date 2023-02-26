function testClassifier_normVraw(MIF_Table_file, MIF_Results_file, calls_inclass, calls_outclass, varargin)
% function testClassifier_normVraw(MIF_Table_file, MIF_Results_file, calls_inclass, calls_outclass, varargin)
% Usage: Compute and save cross-correlation of TEMPLATE with test CALLS.
% Inputs:
%   1. MIF_Table_file [string]: Properties of MIFs saved as table (saved in GreedySearch_MIF)
%   2. MIF_Results_file [string]: Filename to save test classification. 
%   3. calls_inclass [cell of strings]: list of inclass test call spectrograms. 
%   4. calls_outclass [cell of strings]: list of outclass test call spectrograms. 
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

%% Parse input
fun_paramsIN=inputParser;

default_params= struct('comp_routine', 'for', 'xcorr_routine', 'norm');
addRequired(fun_paramsIN, 'MIF_Table_file', @ischar);
addRequired(fun_paramsIN, 'MIF_Results_file', @ischar);
addRequired(fun_paramsIN, 'calls_inclass', @iscell);
addRequired(fun_paramsIN, 'calls_outclass', @iscell);

addParameter(fun_paramsIN,'comp_routine', default_params.comp_routine, @ischar)
addParameter(fun_paramsIN,'xcorr_routine', default_params.xcorr_routine, @ischar)

fun_paramsIN.KeepUnmatched= true;
parse(fun_paramsIN, MIF_Table_file, MIF_Results_file, calls_inclass, calls_outclass, varargin{:});

%% CHECK INPUT TYPE

if iscell(MIF_Table_file)
    MIFfiles = MIF_Table_file;  % LOAD FEAT FILES
elseif ischar(MIF_Table_file)
    temp_data= load(MIF_Table_file);  % LOAD MIF SET
    MIFfiles= temp_data.MIFfiles;
    %     MIFtable= temp_data.MIFtable;
    
    if ~exist('MIFfiles','var')
        error('MIF Table File Not Valid');
    end
else
    error('File Path Not Valid')
end

% Allocate space for correlation arrays
testcorr_inclass= nan(numel(MIFfiles), numel(calls_inclass));
testcorr_outclass= nan(numel(MIFfiles), numel(calls_outclass));
testdetect_inclass= nan(numel(MIFfiles), numel(calls_inclass));
testdetect_outclass= nan(numel(MIFfiles), numel(calls_outclass));
weights= nan(numel(MIFfiles), 1);

%% figure out xcorr_routine and parallel computing options
comp_routine= fun_paramsIN.Results.comp_routine;
if strcmp(fun_paramsIN.Results.comp_routine, 'parfor')
    if ~license('test','Distrib_Computing_Toolbox')
        comp_routine= 'for';
    end
end

%%
% COMPUTE CROSS-CORRELATION

for mifVar = 1:numel(MIFfiles)
    [fragfile, thresh, weight, fs_feat] = pfLoadFeat(MIFfiles{mifVar});
    [template, Flo, Fhi, fs_frag]= pfLoadFrag(fragfile);	%load fragment
    if fs_feat~= fs_frag
        error('fs_feat and fs_frag should be the same!');
    end

    % calculate feature correlation values for inclass and outclass calls
    testcorr_inclass(mifVar,:) = fbam.getXcorr_normVraw(calls_inclass, Flo, Fhi, template, fs_feat, 'comp_routine', comp_routine, 'xcorr_routine', fun_paramsIN.Results.xcorr_routine);
    testcorr_outclass(mifVar,:) = fbam.getXcorr_normVraw(calls_outclass, Flo, Fhi, template, fs_feat, 'comp_routine', comp_routine, 'xcorr_routine', fun_paramsIN.Results.xcorr_routine);

    testdetect_inclass(mifVar,:) = (testcorr_inclass(mifVar,:)>=thresh);
    testdetect_outclass(mifVar,:) = (testcorr_outclass(mifVar,:)>=thresh);
    weights(mifVar) = weight;
end

% SAVE RESULTS IN MIFRESULTS STRUCT
MIFresults.calls_inclass= calls_inclass;
MIFresults.calls_outclass= calls_outclass;
MIFresults.inclasstestcorr = testcorr_inclass;
MIFresults.outclasstestcorr = testcorr_outclass;
MIFresults.inclasstestdetect = testdetect_inclass;
MIFresults.outclasstestdetect = testdetect_outclass;
MIFresults.weights = weights;

save(MIF_Results_file,'MIFfiles','MIFresults');

%SUB FUNCTIONS
%--------------------------------------------------------------------------
function [fragfile,threshold,weight,fs_Hz] = pfLoadFeat(featfile)
load(featfile,'feat')
fragfile = feat.fragfile;
threshold = feat.thresh;
weight = feat.weight;
fs_Hz= feat.fs_Hz;


%--------------------------------------------------------------------------
function [template, Flo, Fhi,fs_Hz] = pfLoadFrag(fragfile)
load(fragfile,'frag')
template = frag.strf;
Flo = frag.freqlower_Hz;
Fhi = frag.frequpper_Hz;
fs_Hz= frag.fs_Hz;

function sortMeritStruct(featFiles, Merit_fName, varargin)
% function sortMeritStruct(featFiles, Merit_fName, varargin)
% Usage: sort features by merit and save as a structure 
%   SORTMERIT(FEATFILES,MPATH) list and sort merit of FEATFILES into array
%   and save under Merit_fName
% Inputs: 
%   1. featFiles [cell array of strings]: path of feature files 
%   2. Merit_fName [string]: filename to save sorted merit structure 
%   (optional) 
%       SORTMERIT(...,CRITERIA) applies criteria to merit values
%           'positive'  - (default) only features with positive weights are
%                     sorted
%           'negative'  - only features with negative weights are sorted
%           'all'       - no criteria is placed on the weight of the features
% 
% -----------------------------------------------------------------------
%   Copyright 2023 Satyabrata Parida, Shi Tong Liu, & Srivatsun Sadagopan

%% CHECK INPUT TPYE
if ~iscell(featFiles)
    error('Input Type Not Valid')
end
if ~ischar(Merit_fName)
    error('Filepath Not Valid')
end

% CREATE SORTED MERIT FILE IF FILE DOES NOT EXIST
% sort merit if files does not exist
feat_count= 1;  % number counter
MeritStruct= struct([]);
for featVar = 1:numel(featFiles)
    load(featFiles{featVar})
    % apply merit criteria
    if isempty(varargin) || (ischar(varargin{1}) && strcmpi(varargin{1},'positive'))
        if isfinite(feat.weight) && feat.weight>=0
            % use only postive and finite merit values
            MeritStruct(feat_count).merit= feat.merit;
            MeritStruct(feat_count).featindex= feat.featindex;
            feat_count = feat_count+1;  % increment counter
        end
    elseif ischar(varargin{1}) && strcmpi(varargin{1},'negative')
        if isfinite(feat.weight) && feat.weight<=0
            % use only negative and finite merit values
            MeritStruct(feat_count).merit= feat.merit;
            MeritStruct(feat_count).featindex= feat.featindex;
            feat_count = feat_count+1;  % increment counter
        end
    elseif ischar(varargin{1}) && strcmpi(varargin{1},'all')
        if isfinite(feat.weight)
            % use only finite merit values
            MeritStruct(feat_count).merit= feat.merit;
            MeritStruct(feat_count).featindex= feat.featindex;
            feat_count = feat_count+1;  % increment counter
        end
    else
        error('Criteria Not Recognized')
    end
end

[~, sortedInds]= sort([MeritStruct.merit], 'descend');
MeritStruct= MeritStruct(sortedInds);

save(Merit_fName, 'MeritStruct')  % save merit file
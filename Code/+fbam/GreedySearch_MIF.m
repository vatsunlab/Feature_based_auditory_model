function GreedySearch_MIF(featFiles, Merit_fName, Table_fName, varargin)
% function GreedySearch_MIF(featFiles, Merit_fName, Table_fName, varargin)
% Usage: Find optimal threshold & merit and generate MIF set
%   GREEDYSEARCH(featFiles, Merit_fName, Table_fName) get set of MIFs from features
%   listed by featFiles and saving the resulting MIF Table under Table_fName. A
%   mat file of the sorted merit of features will be created at Merit_fName, if
%   such file does not already exist under Merit_fName.
% Inputs: 
%   1. featFiles [cell array of strings]: filenames of all feature files 
%   2. Merit_fName [string]: filename of the saved merit (structure ) file 
%   3. Table_fName [string]: filename of table file to be saved after
%       finding the MIF set 
%   (optional)
%   GREEDYSEARCH(...,'firstfeat',N) will start the Greedy Search algorithm
%   at the feature with the Nth highest merit value. Default is the feature
%   with the highest merit value.
%
%   GREEDYSEARCH(...,'copy',REFERENCETPATH) will copy the set of MIFs from
%   REFERENCETPATH and recompute their added information.
%
%   CALLED FUNCTIONS: getJointMerit
% 
% -----------------------------------------------------------------------
%   Copyright 2023 Satyabrata Parida, Shi Tong Liu, & Srivatsun Sadagopan


% CHECK INPUT TPYE
if ~iscell(featFiles)
    error('Input Type Not Valid')
end
if ~ischar(Merit_fName) || ~ischar(Table_fName)
    error('Filepath Not Valid')
end

% PARAMETERS
maxFeatN = 20;  % maximum number of features in MIF set

% LOAD SORTED MERIT FILE
if isfile(Merit_fName)
    merit_data= load(Merit_fName);
    merit_data= merit_data.MeritStruct;
%     if ~exist('merit','var'), error('Merit File Not Valid'); end
else
    error('No Merit File Found')
end

% FIND MIF SET
indCopy = find(cellfun(@(x) ischar(x) && strcmpi(x,'copy'), varargin));
if isempty(indCopy)
    % GENERATE NEW MIF SET
    MIF = [];  % initialize
    % DETERMINE STARTING FEATURE
    indFeat1 = find(cellfun(@(x)ischar(x) && strcmpi(x,'firstfeat'), varargin));
    if isempty(indFeat1)
        % default first feature is one with max merit
        MIF(1,:) = [merit_data(1).featindex, merit_data(1).merit];
    elseif isnumeric(varargin{indFeat1+1})
        MIF(1,:) = [merit(varargin{indFeat1+1},2), merit(varargin{indFeat1+1},1)];
    else
        error('Starting Feature Not Recognized')
    end
    
    % GREEDY SEARCH ALGORITHM
    while size(MIF,1)<maxFeatN
        min_addedI = [];  % initialize
        for featVar = 1:length(merit_data)
            load(featFiles{merit_data(featVar).featindex})  % cycle through all features in merit list
            % compute f_c and f_cbar of feature
            f2_c = (feat.inclasscorr>=feat.thresh);
            f2_cbar = (feat.outclasscorr>=feat.thresh);
            % find next feature that will add the most merit
            added_I = [];  % initialize
            for mifVar = 1:size(MIF,1)
                load(featFiles{MIF(mifVar,1)})  % cycle through existing MIFs
                f1_c = (feat.inclasscorr>=feat.thresh);
                f1_cbar = (feat.outclasscorr>=feat.thresh);
                
                added_I= [added_I, fbam.getJointMerit(f1_c, f1_cbar, f2_c, f2_cbar)];
            end
            added_I(added_I<0) = 0;  % in case of negative mutual information
            min_addedI(featVar) = min(added_I);
        end
        
        [Ik,n_max] = max(min_addedI);  % find feature of maximum added information
        
        if Ik>0
            MIF = [MIF; merit_data(n_max).featindex Ik];
        else
            break;  % if no information can be added, end Greedy Search
        end
%         disp(size(MIF,1))
    end
elseif ischar(varargin{indCopy+1})
    % DUPLICATE MIF SET FROM REFERENCE TABLE FILE
    load(varargin{indCopy+1})
    
    MIF = []; % will contain info about added MIFs
    % since merit is sorted, need to find corresponding index of first MIF
    % since first fragment is NOT necessarily the one with max info
    load(MIFfiles{1})
    MIF(1,:) = [feat.featindex feat.merit];
    
    for featVar = 2:1:numel(MIFfiles)  % skip first feature
        load(MIFfiles{featVar})
        n = feat.featindex;
        % compute f_c and f_cbar of feature
        f2_c = (feat.inclasscorr>=feat.thresh);
        f2_cbar = (feat.outclasscorr>=feat.thresh);
        added_I = [];  % initialize
        for mifVar = 1:1:size(MIF,1)
            % cycle through existing MIFs, correct for different numbering
            % scheme if input file list only
            load(featFiles{mifVar})  % list contains MIFs only
            
            % recompute added information
            f1_c = (feat.inclasscorr>=feat.thresh);
            f1_cbar = (feat.outclasscorr>=feat.thresh);
            
            added_I = [added_I, fbam.getJointMerit(f1_c,f1_cbar,f2_c,f2_cbar)];
        end
        added_I(added_I<0) = 0;  % in case of negative mutual information
        Ik = min(added_I);
        
        MIF = [MIF; n Ik];
    end
    
else
    error('Input Not Recognized')
end

% GENERATE MIF TABLE
if ~exist('MIFn','var'), MIFn = MIF(:,1); end
% create an MIF.mat file with all info
MIFinfo = zeros(size(MIF,1),8);  % initialize
MIFfiles = cell(size(MIF,1),1);
for featVar = 1:1:size(MIF,1)
    % correct for different numbering scheme if input file list only
    % contains MIFs
    if numel(featFiles)==numel(MIFn)
        MIFfiles{featVar} = featFiles{featVar};  % list contains MIFs only
    else
        MIFfiles{featVar} = featFiles{MIFn(featVar)};  % list contains all feats in directory only
    end       
    
    load(MIFfiles{featVar});
    load(feat.fragfile);
    MIFinfo(featVar,:) = [MIF(featVar,1), MIF(featVar,2), feat.merit feat.thresh,...
        feat.weight, frag.centerfreq, frag.bandwidth, frag.duration];
end
MIFtable = array2table(MIFinfo,'VariableNames',{'Fragindex','AddedI',...
    'Merit','Threshold','Weight','CF','BW','Duration'});
save(Table_fName,'MIFtable','MIFfiles')
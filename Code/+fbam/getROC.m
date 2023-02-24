function  [AUC, roc_data, test_detect_inclass, test_detect_outclass, threshold_edges]= getROC(result_fname, figNum)
% Usage: GETROC Generate ROC curve based on classifier testing results
%   GETROC(result_fname) plots ROC and DET curves of classifier data in result_fname
%
%   AUC = GETROC(result_fname) outputs Area Under the Curve of ROC. Will NOT plot
%   ROC or DET curves
%
%   [roc_data,DETECT1,DETECT2,TSTEP,AUC] = GETROC(result_fname) 
% outputs rate data , 
%   inclass detect array DETECT1, inclass detect
%   array DETECT2, and threshold step vector THSTEP
% Inputs:
%   1. result_fname [string]: test output filename to load 
%   2. figNum [scalar int]: figure number to plot 
% Outputs:
%   1. roc_data [structure]: Fields are hit, false alram, and missed detection rate
%   2. test_detect_inclass
% -----------------------------------------------------------------------
%   Copyright 2023 Satyabrata Parida, Shi Tong Liu, & Srivatsun Sadagopan


% CHECK INPUT TPYE
if ~ischar(result_fname)
    error('File Path Not Valid')
end

if ~exist('figNum', 'var')
    figNum= 11;
end

% LOAD RESULTS FILE
load(result_fname);
if ~exist('MIFfiles','var') || ~exist('MIFresults','var')
    error('MIF Result File Not Valid')
end

% COMPUTES WEIGHTED SUM OF MIFS
L = length(MIFresults.weights);
% find direction of summation, sum across all MIFs
s1dim = 1; % find(size(MIFresults.inclasstestdetect)==L);
s2dim = 1; % find(size(MIFresults.outclasstestdetect)==L);

% match weight vector dimension to inclasstestdetect array dimension
wdim = find(size(MIFresults.weights)==L);
if s1dim~=wdim
    weight1 = transpose(MIFresults.weights);
else
    weight1 = MIFresults.weights;
end

% match weight vector dimension to outclasstestdetect array dimension
if s2dim~=wdim
    weight2 = transpose(MIFresults.weights);
else
    weight2 = MIFresults.weights;
end

% skip features with Inf weights
weight1(abs(weight1) == Inf)=0;
weight2(abs(weight2) == Inf)=0;

% detection array of weight sum
test_detect_inclass= sum(bsxfun(@times, MIFresults.inclasstestdetect,weight1),s1dim);
test_detect_outclass = sum(bsxfun(@times, MIFresults.outclasstestdetect,weight2),s2dim);
% threshold step vector
% threshold_edges= [0 min(test_detect_outclass):(max(test_detect_inclass)-min(test_detect_outclass))/100:max(test_detect_inclass)];
threshold_edges= [0 prctile(unique([test_detect_inclass, test_detect_outclass]), 1:100) inf];

roc_data= struct('hit', nan, 'false_alarm', nan, 'miss', nan);
for thresh_var = 1:1:numel(threshold_edges)
    roc_data(thresh_var).hit = sum(test_detect_inclass>=threshold_edges(thresh_var))/numel(test_detect_inclass);  % true positive
    roc_data(thresh_var).false_alarm = sum(test_detect_outclass>=threshold_edges(thresh_var))/numel(test_detect_outclass);  % false positive
    roc_data(thresh_var).miss = sum(test_detect_inclass<threshold_edges(thresh_var))/numel(test_detect_inclass);  % missed detection
end


AUC = trapz(fliplr([roc_data.false_alarm]), fliplr([roc_data.hit]));  % numerical integration of AUC

% PLOT/OUTPUT OPTIONS
if nargout==0
    % PLOT ROC AND DET CURVE IF NO FUNCTION OUTPUT REQUESTED

    corr_xlim= [test_detect_inclass, test_detect_outclass];
    corr_xlim= [min(corr_xlim)-.05*range(corr_xlim), max(corr_xlim)+.05*range(corr_xlim)];

    figSize_in= [2 1 8 4];
    figure_prop_name = {'PaperPositionMode','units','Position', 'Renderer'};
    figure_prop_val =  { 'auto'            ,'inches', figSize_in, 'painters'};  % [Xcorner Ycorner Xwidth Ywidth]
    figure(figNum);
    set(gcf,figure_prop_name,figure_prop_val);
    clf;
    fig1_han= tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'tight');

    nexttile;
    sp_ax(1)= gca;  % Weighted final response for inclass and outclass calls 
    hold on
    plot(test_detect_inclass, ones(size(test_detect_inclass)), 'xb', 'MarkerSize', 8);
    plot(test_detect_outclass, zeros(size(test_detect_outclass)), 'xr', 'MarkerSize', 8);
    xlim(corr_xlim);
    ylim([-.1, 1.1]);
    legend('Inclass', 'Outclass', 'Location', 'east');
    xlabel('Correlation');
    set(gca, 'YTick', [0, 1], 'YTickLabel', {'Out', 'In'})

    nexttile;
    sp_ax(2)= gca;  % Weighted final response for inclass and outclass calls 
    plot([roc_data.false_alarm], [roc_data.hit],'-o','MarkerSize', 6); hold on
    set(gca,'XLim',[0 1],'YLim',[0 1],...
        'XTick',0:0.2:1,'YTick',0:0.2:1,...
        'XTickLabel',{'0','20','40','60','80','100'},...
        'YTickLabel',{'0','20','40','60','80','100'},...
        'XGrid','on','YGrid','on'); axis square
    set(get(gca,'XLabel'),'String','False Alarm Rate (%)');
    set(get(gca,'YLabel'),'String','Hit Rate (%)');
    if isempty(findobj('Tag','diagline'))
        g=line([0 1],[0 1],'Color',[0.5 0.5 0.5]','LineStyle','--');
        set(g,'Tag','diagline');
    end
    box off;
    
    title(fig1_han, sprintf('AUC=%.2f', AUC))
    set(findall(gcf,'-property','FontSize'),'FontSize', 12);

end

% 
% % SUB FUNCTIONS
% %--------------------------------------------------------------------------
% function Y = probit(X)
% %probit axis warping for DET curve
% Y = sqrt(2)*erfinv(2*X-1);
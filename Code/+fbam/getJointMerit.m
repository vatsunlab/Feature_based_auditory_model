function addedI = getJointMerit(f1_c,f1_cbar,f2_c,f2_cbar)
% function addedI = getJointMerit(f1_c,f1_cbar,f2_c,f2_cbar)
% Usage: Compute joint added merit/information between two features (f1 and
% f2) beond the merit of f1 alone. 
% Inputs: 
%   1. f1_c [binary vector]: (correct) inclass detections for feat1
%   2. f1_cbar [binary vector]: (incorrect) outclass detections for feat1
%   3. f2_c [binary vector]: (correct) inclass detections for feat2
%   4. f2_cbar [binary vector]: (incorrect) outclass detections for feat2
% Output: 
%   1. addedI [scalar]: joint added merit (beyond the merit of f1)
% 
% -----------------------------------------------------------------------
%   Copyright 2023 Satyabrata Parida, Shi Tong Liu, & Srivatsun Sadagopan

%%
% p(c) assumed to be 0.1
p_c = 0.1;
p_cbar = 1-p_c;

% p(f)
p_f1 = (sum(f1_c==1)+sum(f1_cbar==1))/(numel(f1_c)+numel(f1_cbar));
p_f1bar = 1-p_f1;
p_f2 = (sum(f2_c==1)+sum(f2_cbar==1))/(numel(f2_c)+numel(f2_cbar));
p_f2bar = 1-p_f2;

% p(f,c) = p(f|c) * p(c)
p_f1_c = sum(f1_c==1)/numel(f1_c) * p_c;
p_f2_c = sum(f2_c==1)/numel(f2_c) * p_c;

% p(f,cbar) = p(f|cbar) * p(cbar)
p_f1_cbar = sum(f1_cbar==1)/numel(f1_cbar) * p_cbar;
p_f2_cbar = sum(f2_cbar==1)/numel(f2_cbar) * p_cbar;

% p(fbar,c) = p(fbar|c) * p(c)
p_f1bar_c = sum(f1_c==0)/numel(f1_c) * p_c;
p_f2bar_c = sum(f2_c==0)/numel(f2_c) * p_c;

% p(fbar,cbar) = p(fbar|cbar) * p(cbar)
p_f1bar_cbar = sum(f1_cbar==0)/numel(f1_cbar) * p_cbar;
p_f2bar_cbar = sum(f2_cbar==0)/numel(f2_cbar) * p_cbar;

% I(F,C) = p(f,c)*log2(p(f,c)/p(f)p(c)) + etc 
    
t1 = p_f1_c * log2(p_f1_c/(p_f1*p_c)); if isnan(t1), t1 = 0; end
t2 = p_f1_cbar * log2(p_f1_cbar/(p_f1*p_cbar)); if isnan(t2), t2 = 0; end
t3 = p_f1bar_c * log2(p_f1bar_c/(p_f1bar*p_c)); if isnan(t3), t3 = 0; end
t4 = p_f1bar_cbar * log2(p_f1bar_cbar/(p_f1bar*p_cbar)); if isnan(t4), t4 = 0; end
I1 = t1+t2+t3+t4;

t1 = p_f2_c * log2(p_f2_c/(p_f2*p_c)); if isnan(t1), t1 = 0; end
t2 = p_f2_cbar * log2(p_f2_cbar/(p_f2*p_cbar)); if isnan(t2), t2 = 0; end
t3 = p_f2bar_c * log2(p_f2bar_c/(p_f2bar*p_c)); if isnan(t3), t3 = 0; end
t4 = p_f2bar_cbar * log2(p_f2bar_cbar/(p_f2bar*p_cbar)); if isnan(t4), t4 = 0; end
I2 = t1+t2+t3+t4;
    
% joint mutual information
%I(F1,F2;C) = p(f1,f2|C) * p(C) * log2 (p(f1,f2|C)*p(C)/p(f1,f2)*p(C)) + etc

% set up 
f1f2_c = or(f1_c,f2_c);
f1f2_cbar = or(f1_cbar,f2_cbar);
 
p_f1f2 = (sum(f1f2_c==1)+sum(f1f2_cbar==1))/(numel(f1f2_c)+numel(f1f2_cbar));
p_f1barf2bar = 1 - p_f1f2;
 
p_f1f2_c = sum(f1f2_c==1)/numel(f1f2_c)*p_c;
p_f1f2_cbar = sum(f1f2_cbar==1)/numel(f1f2_cbar)*p_cbar;
p_f1barf2bar_c = sum(f1f2_c==0)/numel(f1f2_c)*p_c;
p_f1barf2bar_cbar = sum(f1f2_cbar==0)/numel(f1f2_cbar)*p_cbar;
 
t1 = p_f1f2_c * log2(p_f1f2_c/(p_f1f2*p_c)); if isnan(t1), t1 = 0; end
t2 = p_f1f2_cbar * log2(p_f1f2_cbar/(p_f1f2*p_cbar)); if isnan(t2), t2 = 0; end
t3 = p_f1barf2bar_c * log2(p_f1barf2bar_c/(p_f1barf2bar*p_c)); if isnan(t3), t3 = 0; end
t4 = p_f1barf2bar_cbar * log2(p_f1barf2bar_cbar/(p_f1barf2bar*p_cbar)); if isnan(t4), t4 =0; end
 
I12 = t1+t2+t3+t4;

addedI = I12-I1; % I(F1,F2;C) - I(F1;C) where F1 = already selected feature (i.e., info that's already there)
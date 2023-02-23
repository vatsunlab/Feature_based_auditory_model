function I1 = getMerit(f1_c,f1_cbar)
% function I1 = getMerit(f1_c,f1_cbar)
% Usage: get merit of a feature (based on the mutual information equation)
% Input: 
%   1. f1_c [binary vector]: inclass detections (correctly estimated inclass calls)
%   2. f1_cbar [binary vector]: outclass detections (incorrectly estimated outclass calls)
% Output: 
%   1. I1 [scalar]: Merit estimated as the mutual information between
%       predicted and true categories 
% 
% -----------------------------------------------------------------------
%   Copyright 2023 Satyabrata Parida, Shi Tong Liu, & Srivatsun Sadagopan


p_c = 0.1;
p_cbar = 1-p_c;

% p(f)
p_f1 = (sum(f1_c==1)+sum(f1_cbar==1))/(numel(f1_c)+numel(f1_cbar));
p_f1bar = 1-p_f1;

% p(f,c) = p(f|c) * p(c)
p_f1_c = sum(f1_c==1)/numel(f1_c) * p_c;

% p(f,cbar) = p(f|cbar) * p(cbar)
p_f1_cbar = sum(f1_cbar==1)/numel(f1_cbar) * p_cbar;

% p(fbar,c) = p(fbar|c) * p(c)
p_f1bar_c = sum(f1_c==0)/numel(f1_c) * p_c;

% p(fbar,cbar) = p(fbar|cbar) * p(cbar)
p_f1bar_cbar = sum(f1_cbar==0)/numel(f1_cbar) * p_cbar;

% I(F,C) = p(f,c)*log2(p(f,c)/p(f)p(c)) + etc
t1 = p_f1_c * log2(p_f1_c/(p_f1*p_c)); if isnan(t1), t1 = 0; end
t2 = p_f1_cbar * log2(p_f1_cbar/(p_f1*p_cbar)); if isnan(t2), t2 = 0; end
t3 = p_f1bar_c * log2(p_f1bar_c/(p_f1bar*p_c)); if isnan(t3), t3 = 0; end
t4 = p_f1bar_cbar * log2(p_f1bar_cbar/(p_f1bar*p_cbar)); if isnan(t4), t4 = 0; end
I1 = t1+t2+t3+t4;
function W = getWeight(f_c,f_cbar,fbar_c,fbar_cbar)
% function W = getWeight(f_c,f_cbar,fbar_c,fbar_cbar)
% Usage: get weight of a feature (based on log-likelihood ratio) using
%   detections/misses for inclass and outclass calls 
% Inputs: 
%   1. f_c [binary vector]: (correct) inclass detections 
%   2. f_cbar [binary vector]: (incorrect) outclass detections 
%   3. fbar_c [binary vector]: (incorrect) inclass misses 
%   4. fbar_cbar [binary vector]: (correct) outclass misses 
% Output: 
%   1. W [scalar]: weight of the feature (estimated as the log-likelihood ratio) 
% 
% -----------------------------------------------------------------------
%   Copyright 2023 Satyabrata Parida, Shi Tong Liu, & Srivatsun Sadagopan

numer = sum(f_c==1)/numel(f_c);
denom = sum(f_cbar==1)/numel(f_cbar);
if denom==0, denom = 1/numel(f_cbar); end
d1 = log2(numer/denom);

numer = sum(fbar_c==1)/numel(fbar_c);
denom = sum(fbar_cbar==1)/numel(fbar_cbar);
if denom==0, denom = 1/numel(fbar_cbar); end
d2 = log2(numer/denom);

W = d1-d2;
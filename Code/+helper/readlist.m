function list_out= readlist(listfile, root_dir)
% function list_out= readlist(listfile, root_dir)
% Usage: Loads content of .txt into cell array of strings 
% Inputs: 
%   1. listfile [string]: name of txt file 
%   2. root_dir [string]: if content of listfile are relative to the path - root_dir
% Output: 
%   1. list_out [cell array]: content of .txt as a cell array of strings 
% 
% -----------------------------------------------------------------------
%   Copyright 2023 Satyabrata Parida, Shi Tong Liu, & Srivatsun Sadagopan

if ~exist('root_dir', 'var')
    root_dir= '';
elseif ~strcmp(root_dir(end), filesep)
    root_dir= [root_dir, filesep];
end


list_out = table2array(readtable(listfile,'delimiter','\n','readvariablenames',false));
if strcmpi(list_out(1,:),'')
    list_out = list_out(2:end,:);
end

list_out= fullfile(root_dir, list_out);
end
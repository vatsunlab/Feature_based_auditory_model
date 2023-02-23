function create_dir(inDirs)
% function create_dir(inDirs)
% Usage: Skip if directory exists, otherwise create 
% Input [string or cell]: inDirs -> directory or directories to create 
% 
% -----------------------------------------------------------------------
%   Copyright 2023 Satyabrata Parida, Shi Tong Liu, & Srivatsun Sadagopan

if ischar(inDirs)
    if ~isfolder(inDirs)
        mkdir(inDirs);
    end
elseif iscell(inDirs)
    for dirVar=1:length(inDirs)
        curDir= inDirs{dirVar};
        if ~isfolder(curDir)
            mkdir(curDir);
        end            
    end
else 
    error('Input should either be a string or a cell');
end
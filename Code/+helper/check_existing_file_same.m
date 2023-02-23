% function check_existing_file_same(data, fileName)
% Usage: Check if data (input #1) is identical to data stored in fileName (input #2)
% Inputs: 
%   1. data: [any type] data to be compared 
%   2. fileName: [string] compare data with data stored in this fileName 
% Outputs: 
%   None (just error if not the same) 
% 
% -----------------------------------------------------------------------
%   Copyright 2023 Satyabrata Parida, Shi Tong Liu, & Srivatsun Sadagopan

function check_existing_file_same(data, fileName)

[~,~,file_ext]= fileparts(fileName);

if iscell(data) && strcmp(file_ext, '.txt')

    if ~exist(fileName, 'file')
        if exist('writecell', 'file')
            writecell(data, fileName);
        else
            writetable(cell2table(data), fileName, 'WriteVariableNames', false);
        end
    else
        data_existing= helper.readlist2(fileName);
        if ~isequal(data_existing, data)
            error("Saved file list and current file list do not match.");
        end
    end

elseif strcmp(file_ext, '.mat')
    if ~exist(fileName, 'file')
        save(fileName, 'data');
    else
        data_existing= load(fileName);
        data_existing= data_existing.data;
        if isfield(data_existing, 'use_NoisyTraining') && isfield(data, 'use_CT0_NT1_RT2')
            if data_existing.use_NoisyTraining == data.use_CT0_NT1_RT2
                warning("ignoring fieldname change: from use_NoisyTraining to use_CT0_NT1_RT2");
            else
                error("Saved file list and current file list do not match.");
            end

            data_existing= rmfield(data_existing, 'use_NoisyTraining');
            data= rmfield(data, 'use_CT0_NT1_RT2');
        end

        if ~isequal(data_existing, data)
            error("Saved file list and current file list do not match.");
        end
    end

else
    error('Function not ready for file type = %s', file_ext);
end

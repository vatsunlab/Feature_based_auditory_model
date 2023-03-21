function dir_struct = bookkeep_dirstruct(dir_struct)


% if strcmp(out_dir_arg_type, 'default')
% Check for existing FBAM_dir
count= dir([dir_struct.FBAM_dir '*']);
count= numel(count);
if count>0
    % means folder already exists
    temp_FBAM_dir= strrep(sprintf('%s_run%d', dir_struct.FBAM_dir, count), dir_struct.Root_out_dir, '');
    inp_str= input(sprintf('Output directory (%s) already exists. \nCreate new (n) or reuse the same (s) folder?', temp_FBAM_dir), 's');
    if strcmpi(inp_str, 'n')
        count= numel(count)+1;
    end
else
    % first time
    count= count+1;
end
dir_struct.FBAM_dir= sprintf('%s_run%d%s', dir_struct.FBAM_dir, count, filesep);

% elseif strcmp(out_dir_arg_type, 'custom')
%
%     if isfolder(dir_struct.FBAM_dir) % means folder already exists, so ask whether user wants a new folder or reuse the same folder
%         inp_str= input(sprintf('Output directory (%s) already exists. \nCreate new (n) or reuse the same (s) folder?', dir_struct.FBAM_dir), 's');
%         if strcmpi(inp_str, 'n')
%             if strcmp(dir_struct.FBAM_dir(end), filesep)
%                 dir_struct.FBAM_dir= dir_struct.FBAM_dir(1:end-1);
%             end
%             str2serarch= extractBefore(dir_struct.FBAM_dir, '_run');
%             if isempty(str2serarch)
%                 str2serarch= dir_struct.FBAM_dir;
%             end
%
%             count= dir([str2serarch '*']);
%             count= numel(count);
%             prev_post_fix= sprintf('_run%d', count);
%             new_post_fix= sprintf('_run%d', count+1);
%
%             if strcmp(dir_struct.FBAM_dir(end-(numel(prev_post_fix)-1):end), prev_post_fix)
%                 dir_struct.FBAM_dir= strrep(dir_struct.FBAM_dir, prev_post_fix, new_post_fix);
%             else
%                 dir_struct.FBAM_dir= sprintf('%s_run%d%s', dir_struct.FBAM_dir, count+1, filesep);
%             end
%         end
%     end
% end

% final check to make sure dirnames end with filesep
dir_struct.mel_spectrogram_dir= helper.get_full_path(fullfile(dir_struct.mel_spectrogram_dir, filesep));
dir_struct.Root_out_dir= helper.get_full_path(dir_struct.Root_out_dir);
dir_struct.FBAM_dir= helper.get_full_path(fullfile(dir_struct.FBAM_dir, filesep));
dir_struct.FBAM_list_dir= sprintf('%strain_test_list%s', dir_struct.FBAM_dir, filesep);

end
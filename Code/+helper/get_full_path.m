function full_path = get_full_path(in_path)

parent_dir= [fileparts(pwd), filesep];
cur_dir= [pwd, filesep];

if contains(in_path, ['.' filesep])
    % need to convert relative path to absolute path
    split_names= strsplit(in_path, filesep);

    %% is the first folder absolute or rel. to parent or current
    if strcmp(split_names{1}, '.')
        full_path= pwd;

    elseif strcmp(split_names{1}, '..')
        full_path= fileparts(pwd);
    else
        full_path= split_names{1};
    end

    %%
    for splitVar=2:length(split_names)
        cur_str= split_names{splitVar};
        if strcmp(cur_str, '.')
            % do nothing
        elseif strcmp(cur_str, '..')
            full_path= fileparts(full_path);
        else
            full_path= fullfile(full_path, cur_str);
        end
    end
else 
    full_path= in_path;
end


if strcmp(in_path(end), filesep)
    full_path= fullfile(full_path, filesep);
end
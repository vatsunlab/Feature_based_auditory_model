function train_FB_auditory_model(inclass_call_type, dir_struct, model_params)

% inclass_call_type= 'Wheek'; % call type
% xcorr_routine= 'norm'; % 'norm' or 'raw' or 'bf_norm' % bf_norm means biologically feasible normalization

num_MIFsets= model_params.num_MIFsets;
num_fragments= model_params.num_fragments;  % number of fragments/features
fs_Hz= model_params.fs_Hz; % binwidth = 1/fs_Hz

% comp_routine= 'parfor'; % 'gpu' or 'parfor' or 'for'
% parfor is over in-class and out-class calls for each fragment
% do_frag= 1;
% do_greedy_search= 1;
% do_test= 1;
% do_plot_test_roc= 1;

% %%  Directory structure
% dir_struct.Root_FBAM_dir= fileparts(pwd);
% dir_struct.RootOutDir= [dir_struct.Root_FBAM_dir filesep 'Trained_models' filesep];
% dir_struct.FBAM_dir= sprintf('%s%s_vs_rest_FBAM_%s%s', dir_struct.RootOutDir, inclass_call_type, xcorr_routine, filesep); % xcorr_routine should be in the name because a different model
% dir_struct.FBAM_list_dir= sprintf('%strain_test_list%s', dir_struct.FBAM_dir, filesep);

%% Convert paths to absolute paths 
dir_struct.FBAM_dir= helper.GetFullPath(dir_struct.FBAM_dir);
dir_struct.FBAM_list_dir= helper.GetFullPath(dir_struct.FBAM_list_dir);
dir_struct.mel_spectrogram_dir= helper.GetFullPath(dir_struct.mel_spectrogram_dir);
dir_struct.Root_out_dir= helper.GetFullPath(dir_struct.Root_out_dir);

%% Other simulation parameters
simulation_params= struct('inclass_call_type', inclass_call_type, 'fs_Hz', model_params.fs_Hz, 'NumOfFragments_All', model_params.num_fragments, 'xcorr_routine', model_params.xcorr_routine);
simul_param_fName= sprintf('%sSimulationParams.mat', dir_struct.FBAM_dir);
helper.check_existing_file_same(simulation_params, simul_param_fName);

%% Loop over calls
for MIFset_num=1:num_MIFsets

    %%
    fragments_dir= fullfile(dir_struct.FBAM_dir, 'fragments', filesep);
    features_dir= fullfile(dir_struct.FBAM_dir, 'features', filesep);
    dir_struct.MIF_out_dir= sprintf('%soutput_MIFset%d%s', dir_struct.FBAM_dir, MIFset_num, filesep);
    helper.create_dir({fragments_dir, features_dir, dir_struct.MIF_out_dir}); % check if these dirs exist, if not create

    existing_mif_inds= [];
    if MIFset_num>1
        for prevMIFset_dirVar=1:(MIFset_num-1)
            prev_mif_dir= sprintf('%soutput_MIFset%d%s', dir_struct.FBAM_dir, prevMIFset_dirVar, filesep);
            if isfolder(prev_mif_dir)
                cur_mif_set= load([prev_mif_dir 'MIFtable.mat']);
                cur_mif_set= cur_mif_set.MIFfiles;
                [~, cur_mif_set]= fileparts(cur_mif_set);
                if ischar(cur_mif_set) % means only one MIF in the current set
                    cur_mif_set= {cur_mif_set}; % have to convert into cell because cellfun and sscanf behave differently when numel = 1 (vs numel > 1)
                end

                existing_mif_inds= [existing_mif_inds(:); cellfun(@(x) sscanf(x, 'feat%d'), cur_mif_set)];
            end
        end
        if isempty(existing_mif_inds)
            error('No existing MIF inds. Set MIFset_num to 1.');
        end
    end

    %%
    MIF_Merit_file= fullfile(dir_struct.MIF_out_dir, 'Merit_AllFeat.mat');  % sorted merit file
    MIF_Table_file= fullfile(dir_struct.MIF_out_dir, 'MIFtable.mat');  % sorted MIF table file
    MIF_Results_file_train= fullfile(dir_struct.MIF_out_dir, 'train_MIFresults.mat');  % sorted MIF result file
    MIF_Results_file_test= fullfile(dir_struct.MIF_out_dir, 'test_MIFresults.mat');  % sorted MIF result file

    %     if ~exist(MIF_Results_file, 'file')

    %% Initialize filenames for training/testing lists
    fNameStruct= struct( ...
        'inclass_frag',     [dir_struct.FBAM_list_dir 'inclass_files_frag.txt'], ...
        'inclass_train',    [dir_struct.FBAM_list_dir 'inclass_files_train.txt'], ...
        'inclass_test',     [dir_struct.FBAM_list_dir 'inclass_files_test.txt'], ...
        'outclass_train',   [dir_struct.FBAM_list_dir 'outclass_files_train.txt'], ...
        'outclass_test',    [dir_struct.FBAM_list_dir 'outclass_files_test.txt']);

    %% Training: characterize features
    FragFiles= cellfun(@(s) sprintf('%sfrag%0.4d.mat', fragments_dir, s), num2cell(1:num_fragments),'UniformOutput',false)';
    FeatFiles= cellfun(@(s) sprintf('%sfeat%0.4d.mat', features_dir, s), num2cell(1:num_fragments),'UniformOutput',false)';

    if MIFset_num==1
        rng(2); % set seed for reproducibility

        if model_params.do_frag
            fbam.generate_fragments(helper.readlist(fNameStruct.inclass_frag), FragFiles, fs_Hz);
        end

        % Note that random generator is not used after this        
        fbam.runFeatXcorr_Analysis(FragFiles, FeatFiles, helper.readlist(fNameStruct.inclass_train), helper.readlist(fNameStruct.outclass_train), 'comp_routine', model_params.comp_routine,'xcorr_routine', model_params.xcorr_routine);
        
    end

    %% Training: estimate MIFs
    if model_params.do_greedy_search
        Valid_Feat_Inds= setdiff(1:num_fragments, existing_mif_inds);
        FeatFiles_valid= FeatFiles(Valid_Feat_Inds);

        fbam.sortMeritStruct(FeatFiles_valid, MIF_Merit_file, 'positive');
        fbam.GreedySearch_MIF(FeatFiles, MIF_Merit_file, MIF_Table_file);
        fprintf('Generating ROC curve for training calls...\n')
        fbam.testClassifier_normVraw(MIF_Table_file, MIF_Results_file_train, helper.readlist(fNameStruct.inclass_train), helper.readlist(fNameStruct.outclass_train), 'comp_routine', model_params.comp_routine,'xcorr_routine', model_params.xcorr_routine);
        fprintf('Done generating ROC curve for training calls\n')
    end

    %% Testing
    if model_params.do_test
        fprintf('Generating ROC curve for test calls...\n')
        fbam.testClassifier_normVraw(MIF_Table_file, MIF_Results_file_test, helper.readlist(fNameStruct.inclass_test), helper.readlist(fNameStruct.outclass_test), 'comp_routine', model_params.comp_routine,'xcorr_routine', model_params.xcorr_routine);
        fprintf('Done generating ROC curve for test calls\n')
    end

    if model_params.do_plot_summary
        fprintf('Creating summary figure...\n')
        OutfName= sprintf('%sSummary_%s_fs%.0fHz', dir_struct.MIF_out_dir, inclass_call_type, fs_Hz);
        fbam.plot_summary(fNameStruct, MIF_Table_file, MIF_Results_file_train, MIF_Results_file_test);
        print(OutfName, '-dpng',  '-r600');
        fprintf('All done!!\n')
    end
    %     else
    %         fprintf('Output files already exist for this condition.\n');
    %     end
end
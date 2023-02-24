function plot_summary(fNameStruct, MIF_Table_file, train_result_fname, test_result_fname, figNum)

if ~exist('figNum', 'var')
    figNum= 99;
end

%%
figSize_cm= [3 3 17 20];
figure_prop_name = {'PaperPositionMode','units','Position', 'Renderer'};
figure_prop_val =  { 'auto'            ,'centimeters', figSize_cm, 'painters'};  % [Xcorner Ycorner Xwidth Ywidth]
figure(figNum);
clf;

set(gcf,figure_prop_name,figure_prop_val);

fig_han= tiledlayout(4, 2, 'TileSpacing', 'compact', 'Padding', 'tight');
sp_ax= nan(8,1);
for sp_var=1:8
    nexttile;
    sp_ax(sp_var)= gca;
end

%% First row = example spectrograms
inclass_train_list= helper.readlist(fNameStruct.inclass_train);
demo_in_spctg= load(inclass_train_list{1});
demo_in_spctg= demo_in_spctg.mel_spectrogram_struct;
[~, inclass_ttl_str]= fileparts(inclass_train_list{1});

outclass_train_list= helper.readlist(fNameStruct.outclass_train);
demo_out_spctg= load(outclass_train_list{1});
demo_out_spctg= demo_out_spctg.mel_spectrogram_struct;
[~, outclass_ttl_str]= fileparts(outclass_train_list{1});


axes(sp_ax(1));
imagesc((1:size(demo_in_spctg.mel_S_dB,2))/demo_in_spctg.mel_spect_params.Fs_SG_Hz*1e3, demo_in_spctg.mel_freq_Hz/1e3, demo_in_spctg.mel_S_dB);
set(gca, 'YScale', 'log', 'YDir', 'normal', 'YTick', [.2, 1, 4, 16], 'TickDir', 'both', 'Box', 'off');
xlabel('Time (s)')
ylabel('Freq, kHz')
title(sprintf('Ex(inclass): %s', inclass_ttl_str), 'Interpreter','none');
xlim1= xlim();

axes(sp_ax(2))
imagesc((1:size(demo_out_spctg.mel_S_dB,2))/demo_out_spctg.mel_spect_params.Fs_SG_Hz*1e3, demo_out_spctg.mel_freq_Hz/1e3, demo_out_spctg.mel_S_dB);
set(gca, 'YScale', 'log', 'YDir', 'normal', 'YTick', [.2, 1, 4, 16], 'TickDir', 'both', 'Box', 'off');
xlabel('Time (ms)')
ylabel('Freq, kHz')
title(sprintf('Ex(outclass): %s', outclass_ttl_str), 'Interpreter','none')
ylim_val= ylim();
xlim2= xlim();

xlim_val= [0, max([xlim1,xlim2])];

%% Second row = trained model feature summary
mif_data= load(MIF_Table_file);
mif_filenames= mif_data.MIFfiles;
mif_table_data= mif_data.MIFtable;
cf_center_kHz= mif_table_data.CF_Hz/1e3;
numFeatures= length(cf_center_kHz);
cf_upper_kHz= mif_table_data.CF_Hz .* (2.^ (mif_table_data.BW_octave/2))/1e3;
cf_lower_kHz= mif_table_data.CF_Hz .* (2.^ (-mif_table_data.BW_octave/2))/1e3;
dur_ms= mif_table_data.Duration_sec*1e3;
time_scale= 'log';

best_mif_fname= mif_filenames{1};
best_mif_feat_data= load(best_mif_fname);
best_mif_feat_data= best_mif_feat_data.feat;
best_mif_frag_data= load(best_mif_feat_data.fragfile);
best_mif_frag_data= best_mif_frag_data.frag;
best_feat_time_ms= (1:size(best_mif_frag_data.strf, 2))/best_mif_frag_data.fs_Hz*1e3;
best_feat_CF_kHz= logspace(log10(best_mif_frag_data.freqlower_Hz), log10(best_mif_frag_data.frequpper_Hz), size(best_mif_frag_data.strf,1))/1e3;

axes(sp_ax(3))
hold on;
for featVar=1:numFeatures
    plot([dur_ms(featVar), dur_ms(featVar)], [cf_lower_kHz(featVar), cf_upper_kHz(featVar)], 'r-')
    if strcmp(time_scale, 'linear')
        plot(dur_ms(featVar)+[-20, +20], [cf_center_kHz(featVar), cf_center_kHz(featVar)], 'k-', 'LineWidth', 1.5)
    elseif strcmp(time_scale, 'log')
        plot(dur_ms(featVar)*1.1.^[-1, +1], [cf_center_kHz(featVar), cf_center_kHz(featVar)], 'k-', 'LineWidth', 1.5)
    end
end
set(gca, 'YScale', 'log', 'YTick', [.2, 1, 4, 16]);
set(gca, 'XScale', time_scale)
ylim([min(cf_lower_kHz), max(cf_upper_kHz)])
if strcmp(time_scale, 'linear')
    xlim([0, max(dur_ms)+30])
    set(gca, 'XTick', round(linspace(min(dur_ms), max(dur_ms), 4)/100)*100)
elseif strcmp(time_scale, 'log')
    xlim([min(dur_ms)/1.15, max(dur_ms)*1.15])
    set(gca, 'XTick', round(logspace(log10(min(dur_ms)), log10(max(dur_ms)), 4)/10)*10)
end
xlabel('MIF dur, ms');
ylabel('Bandwidth, kHz');
title(sprintf('MIF summary (#MIFs=%d)', numFeatures))
ylim(ylim_val);

axes(sp_ax(4))
hold on;
imagesc(best_feat_time_ms, best_feat_CF_kHz, best_mif_frag_data.strf)
set(gca, 'YScale', 'log', 'YDir', 'normal', 'YTick', [.2, 1, 4, 16], 'TickDir', 'both', 'Box', 'off');
ylim(ylim_val);
xlim(xlim_val);
xlabel('Time (ms)')
title('Most informative feature')

%% Third row = Training summary

[train_AUC, train_roc_data, train_detect_inclass, train_detect_outclass]= fbam.getROC(train_result_fname, figNum);
corr_xlim_train= [train_detect_inclass, train_detect_outclass];
corr_xlim_train= [min(corr_xlim_train)-.05*range(corr_xlim_train), max(corr_xlim_train)+.05*range(corr_xlim_train)];

axes(sp_ax(5))
hold on
plot(train_detect_inclass, ones(size(train_detect_inclass)), 'xb', 'MarkerSize', 8);
plot(train_detect_outclass, zeros(size(train_detect_outclass)), 'xr', 'MarkerSize', 8);
xlim(corr_xlim_train);
ylim([-.1, 1.1]);
% legend('Inclass', 'Outclass', 'Location', 'east');
xlabel('Correlation');
set(gca, 'YTick', [0, 1], 'YTickLabel', {'Out', 'In'})
% text(0.02, 0.7, {'Training'; 'output'; 'distribution'}, 'Units', 'normalized', 'HorizontalAlignment','left')
title('Training: model output distribution')

axes(sp_ax(6))
hold on
plot([train_roc_data.false_alarm]*100, [train_roc_data.hit]*100,'-o','MarkerSize', 6);
line([0 100],[0 100],'Color',[0.5 0.5 0.5]','LineStyle','--');
set(gca,'XLim',[0 100],'YLim',[0 100]);
set(get(gca,'XLabel'),'String','False Alarm Rate (%)');
set(get(gca,'YLabel'),'String','Hit Rate (%)');
title(sprintf('Training ROC: AUC=%.2f', train_AUC), 'Interpreter','none')

%% Fourth row = Testing summary

[test_AUC, test_roc_data, test_detect_inclass, test_detect_outclass]= fbam.getROC(test_result_fname, figNum);
corr_xlim_test= [test_detect_inclass, test_detect_outclass];
corr_xlim_test= [min(corr_xlim_test)-.05*range(corr_xlim_test), max(corr_xlim_test)+.05*range(corr_xlim_test)];

axes(sp_ax(7))
hold on
plot(test_detect_inclass, ones(size(test_detect_inclass)), 'xb', 'MarkerSize', 8);
plot(test_detect_outclass, zeros(size(test_detect_outclass)), 'xr', 'MarkerSize', 8);
xlim(corr_xlim_test);
ylim([-.1, 1.1]);
% legend('Inclass', 'Outclass', 'Location', 'east');
xlabel('Correlation');
set(gca, 'YTick', [0, 1], 'YTickLabel', {'Out', 'In'})
% text(0.02, 0.7, {'Test'; 'output'; 'distribution'}, 'Units', 'normalized', 'HorizontalAlignment','left')
title('Test: model output distribution')

axes(sp_ax(8))
hold on
plot([test_roc_data.false_alarm]*100, [test_roc_data.hit]*100,'-o','MarkerSize', 6);
line([0 100],[0 100],'Color',[0.5 0.5 0.5]','LineStyle','--');
set(gca,'XLim',[0 100],'YLim',[0 100]);
set(get(gca,'XLabel'),'String','False Alarm Rate (%)');
set(get(gca,'YLabel'),'String','Hit Rate (%)');
title(sprintf('Test ROC: AUC=%.2f', test_AUC), 'Interpreter','none');

%%
set(findall(gcf,'-property','FontSize'),'FontSize', 10);
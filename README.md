# Feature_based_auditory_model

Code to train a feature-based auditory categorization model to categorize a single call/sound type from all other call/sound types. These code are published under Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) license. 

## Directory structure

1 "Code": Contains code files. 
2 "Stimuli": The root directory for different call (sound) types. Each subfolder inside the "Stimuli" folder is considered a different sound/call type. The subfolders should contain sound files (wav or mp3 or any file-extension that Matlab can read using audioread). 
3 "Mel_spect": Mel-scaled spectrogram for each file inside the "Stimuli" folder. 
    * Directory structure of "Stimuli" and "Mel_spect" will be identical (recursively). 
    * "Mel_spect" is automatically populated by running the script Code/create_stim_spectrogram.m.
4 "Trained_models": Folder where trained models are saved as subfolders. 

## Key functions  

(Two) Key functions under the folder "*/Feature_based_auditory_model/Code/". Run these functions from the same folder (i.e., */Feature_based_auditory_model/Code/).
1. `create_stim_spectrogram` -> creates a mel-scaled spectrogram inside the folder "Mel_spect" for each stimulus (recursively) inside the folder "Stimuli". 
2. `run_FB_auditory_model` -> to train a model for a single call type. Output is stored in the folder "Trained_models".  

## Getting started 

1. Change directory to "*/Feature_based_auditory_model/Code/" in Matlab. 
2. Then run the follwing function: `run_FB_auditory_model()`. 
    * A new folder will be created under "*/Feature_based_auditory_model/Trained_models/". 
    * The model runs on files already present in "*/Feature_based_auditory_model/Mel_spect/". 
    * A summary figure (like the following) will appear after completion of model training and testing. 
    * ![(row1) Examplar inclass and outclass spectrograms; (row2) duration and bandwidth summary of all MIFs, the most informative feature for this model; (row3) Model output for all inclass and outclass training calls and the corresponding ROC; (row4) Same format at row3 but for test calls.](https://github.com/vatsunlab/Feature_based_auditory_model/tree/main/Code/example_fig/Summary_Chut_fs1000Hz.png?raw=true)
    


## Training/testing the model for different stimuli 

Note: Folders "Stimuli" and "Mel_spect" already contain guinea pig vocalization stimuli. To run the model on different stimuli, delete those subfolders and add different call types as subfolders inside "Stimuli". Then run (from the folder "/Feature_based_auditory_model/Code/")
1. create_stim_spectrogram. 
    * Note: You may also specify different folders for stimuli and spectrograms as input parameters. See create_stim_spectrogram help for details. 
3. run_FB_auditory_model (after changing the variable "inclass_call_type", which sets the target/inclass call type. All other calls are considered non-target/outclass). 


## References 

If you use the package, please cite the following articles. 
1. Liu, S. T., Montes-Lourido, P., Wang, X., & Sadagopan, S. (2019). Optimal features for auditory categorization. Nature Communications, 10(1), 1302.
2. Parida, S., Liu, S. T., & Sadagopan, S. (2022). Adaptive mechanisms facilitate robust performance in noise and in reverberation in an auditory categorization model. bioRxiv, 2022-09.

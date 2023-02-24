# Feature_based_auditory_model: 
Code to train a feature-based auditory categorization model to categorize a single call/sound type from all other call/sound types. 

## Directory structure: 
* "Code": Contains code files. 
* "Stimuli": The root directory for different call (sound) types. Each subfolder inside the "Stimuli" folder is considered a different sound/call type. The subfolders should contain sound files (wav or mp3 or any file-extension that Matlab can read using audioread). 
* "Mel_spect": Mel-scaled spectrogram for each file inside the "Stimuli" folder. 
    * Directory structure of "Stimuli" and "Mel_spect" will be identical (recursively). 
    * "Mel_spect" is automatically populated by running the script Code/create_stim_spectrogram.m.
* "Trained_models": Folder where trained models are saved as subfolders. 

## Key scripts 
(Two) Key scripts under "Code". Run these scripts from the same folder (i.e., */Feature_based_auditory_model/Code/).
1. create_stim_spectrogram -> creates a mel-scaled spectrogram inside the folder "Mel_spect" for each stimulus (recursively) inside the folder "Stimuli". 
2. full_FBAM_model -> to train a model for a single call type. Output is stored in the folder "Trained_models".  

## Training/testing the model for different stimuli 
Note: Folders "Stimuli" and "Mel_spect" already contain guinea pig vocalization stimuli. To run the model on different stimuli, delete those subfolders and add different call types as subfolders inside "Stimuli". Then run (from the folder "/Feature_based_auditory_model/Code/")
1. create_stim_spectrogram. 
2. full_FBAM_model (after changing the variable "inclass_call_type", which sets the target/inclass call type. All other calls are considered non-target/outclass). 

## References 
If you use the package, please cite the following articles. 
1. Liu, S. T., Montes-Lourido, P., Wang, X., & Sadagopan, S. (2019). Optimal features for auditory categorization. Nature Communications, 10(1), 1302.
2. Parida, S., Liu, S. T., & Sadagopan, S. (2022). Adaptive mechanisms facilitate robust performance in noise and in reverberation in an auditory categorization model. bioRxiv, 2022-09.

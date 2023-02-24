# Feature_based_auditory_model: Code to train feature-based auditory categorization models to categorize a single call/sound type from all other call/sound types. 

## Directory structure: 
* "Code": Code to train and test a feature-based auditory categorization model to classify one type from the rest. 
* "Stimuli": The root directory for different call (sound) types. Each subfolder inside the "Stimuli" folder is considered a different sound/call type. The subfolders should contain sound files (wav or mp3 or any file-extension that matlab can read using audioread). 
* "Mel_spect": Mel-scaled spectrogram for each stimulus inside the "Stimuli" folder. Directory structure of "Stimuli" and "Mel_spect" will be identical. "Mel_spect" is automatically populated by running the script Code/create_stim_spectrogram.m.
* "Trained_models": Folder where trained models are saved as subfolders. 

## (Two) Key scripts under "Code"
1. create_stim_spectrogram -> creates a mel-scaled spectrogram inside the folder "Mel_spect" for each stimulus inside the folder "Stimuli". 
2. full_FBAM_model -> to train a model for a single call type. Output is stored in the folder "Trained_models".  

## Note: Stimuli and Mel_spect already contain guinea pig vocalization stimuli. To run the model on different stimuli, delete those subfolders and add different call types as subfolders inside "Stimuli". Then run
1. create_stim_spectrogram. 
2. full_FBAM_model (after changing the variable "inclass_call_type", which sets the target/inclass call type. Al other calls are considered non-target/outclass). 

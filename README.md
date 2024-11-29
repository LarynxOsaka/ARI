# ARI
Acoustic Roughness Index scripts activated in Praat software.

This repository contains the ARI custom script designed for use with Praat, a free acoustic analysis software.

This script enables users to analyze acoustic parameters from continuous speech and sustained vowel audio files.

Below are step-by-step instructions to help you get started.　　

# Prerequisites
## Download and install Praat:
Visit the Praat website. (https://www.fon.hum.uva.nl/praat/)
Select the version compatible with your operating system (Windows, macOS, or Linux).　　
Download and install the software following the provided instructions.　　

## Prepare the audio files:
Ensure you have the required audio files ready for analysis:
・Continuous Speech Audio File
・Sustained Vowel Audio File
Voice samples should be recorded in an acoustically treated room and stored as a digitised WAV. format with a sampling rate of 44.1 kHz and 16-bit resolution using a head-mounted microphone, and meet the generally required level of signal-to-noise ratio (>30 dB). 
These should be from the same patient to ensure consistency in the analysis.

# How to Use ARI in Praat
## Open the audio files in Praat:
Launch Praat.
Go to Open > Read from file in the menu to load your audio files (both Continuous Speech and Sustained Vowel files).

## Run the ARI script:
In Praat, click on Praat > New Praat Script > Paste the ARI script > 
Once the script is loaded, press the Run button in the script editor to start the process.

## Input parameters in the ARI script:
Enter the following details in the pop-up dialog box:
Objects number: The numbers assigned to the Continuous Speech and Sustained Vowel files in the Praat Objects window.
Number of patients: Input 1 if analyzing data for a single patient.
Save directory: Specify the directory where the analysis results should be saved.
Click OK after entering all parameters.
The script will generate:　　
・Excel file: Lists values for each analyzed parameter.　　
・PNG file: Visual representation of the analysis results.　　

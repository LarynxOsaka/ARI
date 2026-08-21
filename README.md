# Acoustic Roughness Index (ARI)
# 📄 **Reference Publication**  
Kitayama I, Hosokawa K, et al. *A Multivariate Model Incorporating Subharmonic Measurements for Evaluating Vocal Roughness*. npj Digital Medicine 2025 May 20;8(1):295.
[https://doi.org/10.1038/s41746-025-01702-2](https://doi.org/10.1038/s41746-025-01702-2)  

# **📢 Latest Release**

## Version 1.2.0

**Release date:** 2026-08-21

ARI is a Praat-based acoustic analysis tool for the objective assessment of perceived vocal roughness.

Version 1.2.0 is a **workflow and batch-processing update** based on ARI v1.1.1. The release improves usability, file handling, batch safety, result output, and Praat object management while retaining the ARI v1 analysis framework.

## Requirements

- Praat
- Continuous speech recording (CS)
- Sustained vowel recording (SV)

Input audio is automatically standardized when necessary, including resampling to 44.1 kHz, channel selection, and standardized SV extraction.

## Analysis modes

### Single pair

Use this mode to analyze one CS–SV pair already loaded in the Praat Objects window.

- Select the CS and SV by their Sound object numbers.
- CS and SV filenames do **not** have to match.
- SampleID is optional.
- Existing Praat objects are preserved.

### Batch

Use this mode for folder-based analysis.

- Select a folder containing CS WAV files.
- Select a separate folder containing SV WAV files.
- The first 16 filename characters are used as the SampleID.
- Exactly one CS and one SV must exist for each SampleID.

Before analysis, ARI performs a **preflight check** of all file pairs. If any mismatch or duplicate is found, analysis is not started and a preflight report is generated.

## Batch progress

During Batch analysis, the Praat Info window is updated in place to show the current pair, progress, and remaining analyses.

A completion dialog is shown after both Single and Batch runs.

## Output

Results are saved as:

```text
<ResultName>.tsv
```

The file contains one header row followed by one row per analysis.

The first columns include:

```text
SampleID
CS_FileName
SV_FileName
ARI
ABI
...
```

A separate analysis log is saved automatically as:

```text
<ResultName>_log.tsv
```

A preflight report is created only when Batch pairing fails.

## Object handling

ARI v1.2.0 preserves objects that were already present in the Praat Objects window before analysis. Temporary objects created during processing are cleaned up automatically.

Internal CS/SV handling has also been optimized to improve consistency across different input sampling rates and file configurations.

## Main changes from v1.1.1

- Added **Single pair** and **Batch** modes.
- Added folder-based Batch processing.
- Added strict preflight pairing before Batch analysis.
- Added live, non-scrolling progress display.
- Added completion dialogs.
- Added result-linked analysis logs.
- Improved TSV output and filename tracking.
- Improved preservation of existing Praat objects.
- Optimized internal CS/SV processing.
- Consolidated distribution into a single Praat script.

## Version history

### v1.2.0 — 2026-08-21
Workflow and batch-processing update.

### v1.1.1 — 2026-08-21
Maintenance and bug-fix release.

### v1.1.0 — 2025-08-08
Automated preprocessing and output improvements.

## Note

ARI v1.2.0 remains based on the ARI v1 framework and SFEEDS v1.1.0. Major methodological updates are reserved for future versions.

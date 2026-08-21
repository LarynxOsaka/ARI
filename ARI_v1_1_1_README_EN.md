# Acoustic Roughness Index (ARI)

## Version 1.1.1

**Release date:** 2026-08-21

ARI is a Praat-based acoustic analysis tool for the objective assessment of perceived vocal roughness.

Version 1.1.1 is a **maintenance and bug-fix release** based on ARI v1.1.0 and SFEEDS v1.1.0.

## Requirements

- Praat
- Continuous speech recording (CS)
- Sustained vowel recording (SV)

The script automatically standardizes input audio when necessary, including resampling, channel selection, and standardized SV extraction.

## Changes in v1.1.1

- Optimized internal CS/SV handling for more consistent processing across different input conditions.
- Corrected an issue that could affect CS/SV concatenation order during preprocessing.
- Corrected script termination when CS/SV pairing is invalid.
- Changed result output to a proper TSV format.
- Results are now written as **one header row followed by one row per analysis**.
- Added CS and SV filenames to the result table.
- Preserves Praat objects that were already present before the script was started.
- Optimized ABI-related internal processing for improved compatibility with the original ABI implementation.

## Output

Results are saved as:

```text
<Title_of_table>.tsv
```

The first columns include:

```text
FileName
CS_FileName
SV_FileName
ARI
ABI
...
```

The Praat version and individual acoustic parameters are also included.

## Input pairing

Version 1.1.1 retains the legacy Object-number-based workflow.

For multi-pair analysis, corresponding CS and SV recordings are identified using the first 16 characters of their Sound object names.

A redesigned Single/Batch workflow is introduced in ARI v1.2.0.

## Object handling

Objects that existed in the Praat Objects window before ARI was started are preserved. Temporary objects created during analysis are removed automatically.

## Compatibility

ARI v1.1.1 retains the ARI v1 analysis framework and SFEEDS v1.1.0. Internal processing has been optimized while maintaining compatibility with the established ARI workflow.

## Version history

### v1.1.1 — 2026-08-21
Maintenance and bug-fix release.

### v1.1.0 — 2025-08-08
Automated preprocessing, fixed analysis settings, and output improvements.

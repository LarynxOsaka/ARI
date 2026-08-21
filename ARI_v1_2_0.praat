########################################################################
# Acoustic Roughness Index (ARI) v1.2.0
# Workflow / batch-processing update based on ARI v1.1.1.
# Test build 08: completion dialog for Single mode and symmetric preflight reporting.
# - Single: select Sound object numbers; filename matching is NOT required.
# - Batch: choose CS/SV folders; strict 1:1 preflight pairing.
# - Uses chooseFolder$() instead of folder fields inside beginPause.
########################################################################

form ARI v1.2.0
    comment Select analysis mode
    choice Mode 1
        button Single_pair
        button Batch
endform

if mode = 1
    # Single mode uses Sound objects already loaded in the Objects window.
    beginPause: "ARI v1.2.0 - Single pair"
        comment: "Enter the Sound object numbers shown in the Praat Objects window."
        comment: "CS and SV filenames do NOT have to match in Single pair mode."
        integer: "single_cs_sound_no", 0
        integer: "single_sv_sound_no", 0
        comment: "SampleID is optional and may be left blank."
        sentence: "single_sampleid", ""
        sentence: "result_file_name", "ARI_results"
        boolean: "overwrite_result_file", 1
        boolean: "draw_figure", 0
        boolean: "save_figure", 0
    endPause: "Run", 1

    if single_cs_sound_no <= 0
        exitScript: "Enter a valid CS Sound object number."
    endif
    if single_sv_sound_no <= 0
        exitScript: "Enter a valid SV Sound object number."
    endif
    if single_cs_sound_no = single_sv_sound_no
        exitScript: "CS and SV must be different Sound objects."
    endif

    selectObject: single_cs_sound_no
    single_cs_name$ = selected$("Sound")
    if single_cs_name$ = ""
        exitScript: "The specified CS object is not a Sound object."
    endif
    selectObject: single_sv_sound_no
    single_sv_name$ = selected$("Sound")
    if single_sv_name$ = ""
        exitScript: "The specified SV object is not a Sound object."
    endif

    single_cs_object_id = single_cs_sound_no
    single_sv_object_id = single_sv_sound_no

    output_folder$ = chooseFolder$: "Choose output folder for ARI results"
    if output_folder$ = ""
        exitScript: "No output folder was selected."
    endif

elsif mode = 2
    # Native folder dialogs are used for compatibility with Praat 6.2.x.
    # On Windows these dialogs normally reopen at the most recently used location.
    batch_cs_folder$ = chooseFolder$: "Choose folder containing CS WAV files"
    if batch_cs_folder$ = ""
        exitScript: "No CS folder was selected."
    endif

    batch_sv_folder$ = chooseFolder$: "Choose folder containing SV WAV files"
    if batch_sv_folder$ = ""
        exitScript: "No SV folder was selected."
    endif

    output_folder$ = chooseFolder$: "Choose output folder for ARI results"
    if output_folder$ = ""
        exitScript: "No output folder was selected."
    endif

    beginPause: "ARI v1.2.0 - Batch options"
        comment: "Batch pairing uses the first 16 filename characters as SampleID."
        comment: "Exactly one CS and one SV file must exist for every SampleID."
        sentence: "result_file_name", "ARI_results"
        boolean: "overwrite_result_file", 1
        boolean: "draw_figure", 0
        boolean: "save_figure", 0
    endPause: "Run", 1
endif

if save_figure = 1 and draw_figure = 0
    draw_figure = 1
endif

# The v1.1.1 analysis core uses the historical mixed-case variable names.
# Praat variable names are case-sensitive, so map the UI variables explicitly.
draw_Figure = draw_figure
save_Figure = save_figure

result_file$ = output_folder$ + "/" + result_file_name$ + ".tsv"
analysis_log_file$ = output_folder$ + "/" + result_file_name$ + "_log.tsv"
preflight_file$ = output_folder$ + "/ARI_preflight.tsv"

# Object preservation policy:
# Every analysis procedure snapshots all objects that already exist before
# it creates any working objects. Cleanup removes only objects created by
# that analysis. Objects that were already in the Objects window are never
# removed.

header$ = "SampleID" + tab$ + "CS_FileName" + tab$ + "SV_FileName" + tab$ + "ARI" + tab$ + "ABI" + tab$ + "chaoticNoise_Power_of_all"
header$ = header$ + tab$ + "superSubharmonics_Power_of_all" + tab$ + "one_3rdSubharmonics_Power_of_all" + tab$ + "one_halfSubharmonics_Power_of_all"
header$ = header$ + tab$ + "superSubharmonics_of_all" + tab$ + "one_3rdSubharmonics_of_all" + tab$ + "one_halfSubharmonics_of_all"
header$ = header$ + tab$ + "finalhfno6000" + tab$ + "finalhnrd" + tab$ + "finalH1H2" + tab$ + "finalhnrd_ABI60" + tab$ + "finalH1H2_ABI60"
header$ = header$ + tab$ + "cpps" + tab$ + "jitterLocal" + tab$ + "shimmerLocal" + tab$ + "shimmerLocaldB" + tab$ + "psd"
header$ = header$ + tab$ + "gneMaximum" + tab$ + "slope" + tab$ + "tilt" + tab$ + "hnr" + tab$ + "Praatversion"
log_header$ = "Mode" + tab$ + "PairIndex" + tab$ + "TotalPairs" + tab$ + "SampleID" + tab$ + "CS_FileName" + tab$ + "SV_FileName" + tab$ + "Status" + tab$ + "ARI" + tab$ + "ABI" + tab$ + "Praatversion_or_error"

# Result and analysis-log files are initialized only after input validation
# (and, in Batch mode, only after the full preflight check has passed).

# ======================================================================
# SINGLE PAIR MODE
# ======================================================================
if mode = 1
    call prepareOutputFiles

    # No filename/SampleID matching is required in Single mode.
    sampleid$ = single_sampleid$
    marker_file$ = output_folder$ + "/ARI_single_success.tmp"
    stage_file$ = output_folder$ + "/ARI_single_stage.tmp"
    if fileReadable(marker_file$)
        deleteFile: marker_file$
    endif
    if fileReadable(stage_file$)
        deleteFile: stage_file$
    endif

    clearinfo
    writeInfoLine: "ARI v1.2.0"
    appendInfoLine: "Mode: Single pair"
    appendInfoLine: ""
    appendInfoLine: "CS object: ", string$(single_cs_object_id), "  ", single_cs_name$
    appendInfoLine: "SV object: ", string$(single_sv_object_id), "  ", single_sv_name$
    if sampleid$ <> ""
        appendInfoLine: "SampleID: ", sampleid$
    else
        appendInfoLine: "SampleID: (not specified)"
    endif
    appendInfoLine: ""
    appendInfoLine: "Status: Analyzing..."

    sample_id$ = sampleid$
    cs_file_name$ = single_cs_name$
    sv_file_name$ = single_sv_name$
    run_mode$ = "Single"
    pair_index = 1
    total_pairs = 1
    call analyzePair

    if fileReadable(marker_file$)
        result_summary$ = replace$(readFile$(marker_file$), newline$, "", 0)
        deleteFile: marker_file$
        clearinfo
        writeInfoLine: "ARI v1.2.0"
        appendInfoLine: "Mode: Single pair"
        appendInfoLine: ""
        appendInfoLine: "Analysis completed."
        appendInfoLine: result_summary$
        appendInfoLine: ""
        appendInfoLine: "Results: ", result_file$
        appendInfoLine: "Log: ", analysis_log_file$

        # Explicit completion dialog for Single runs, matching Batch behavior.
        beginPause: "ARI v1.2.0 - Single completed"
            comment: "Single-pair analysis completed."
            comment: result_summary$
            comment: "Results: " + result_file$
            comment: "Log: " + analysis_log_file$
        endPause: "OK", 1, 1
    else
        failure_stage$ = "Analysis failed before completion."
        if fileReadable(stage_file$)
            failure_stage$ = replace$(readFile$(stage_file$), newline$, "", 0)
        endif
        appendFileLine: analysis_log_file$, "Single", tab$, "1", tab$, "1", tab$, sampleid$, tab$, "", tab$, "", tab$, "ERROR", tab$, "", tab$, "", tab$, failure_stage$
        clearinfo
        writeInfoLine: "ARI v1.2.0"
        appendInfoLine: "Mode: Single pair"
        appendInfoLine: ""
        appendInfoLine: "Analysis failed."
        appendInfoLine: "Last stage: ", failure_stage$
    endif
    if fileReadable(stage_file$)
        deleteFile: stage_file$
    endif

    # analyzePair already removed only the working/intermediate objects it
    # created. All objects that existed before the analysis were preserved.
    exitScript: ""
endif

# ======================================================================
# BATCH MODE: STRICT PREFLIGHT, 1 CS : 1 SV PER SAMPLEID
# ======================================================================
if mode = 2
    cs_list = Create Strings as file list: "ARI12_CS_file_list", batch_cs_folder$ + "/*.wav"
    number_of_cs = Get number of strings
    sv_list = Create Strings as file list: "ARI12_SV_file_list", batch_sv_folder$ + "/*.wav"
    number_of_sv = Get number of strings

    if number_of_cs = 0
        removeObject: cs_list, sv_list
        exitScript: "No .wav files were found in the CS folder."
    endif
    if number_of_sv = 0
        removeObject: cs_list, sv_list
        exitScript: "No .wav files were found in the SV folder."
    endif

    # Remove a stale report from a previous failed run, but do not create a
    # preflight report unless this run actually finds a mismatch.
    if fileReadable(preflight_file$)
        deleteFile: preflight_file$
    endif
    preflight_errors = 0
    preflight_text$ = ""
    preflight_tsv$ = "SampleID" + tab$ + "CS_count" + tab$ + "SV_count" + tab$ + "CS_FileName(s)" + tab$ + "SV_FileName(s)" + tab$ + "Problem" + newline$

    # Check CS filenames and every unique CS SampleID.
    for i from 1 to number_of_cs
        selectObject: cs_list
        cs_name$ = Get string: i
        if length(cs_name$) < 16
            preflight_errors = preflight_errors + 1
            preflight_tsv$ = preflight_tsv$ + "" + tab$ + "1" + tab$ + "0" + tab$ + cs_name$ + tab$ + "" + tab$ + "CS filename has fewer than 16 characters" + newline$
            preflight_text$ = preflight_text$ + "CS filename <16 characters: " + cs_name$ + newline$
        else
            sid$ = left$(cs_name$, 16)
            seen_before = 0
            if i > 1
                for j from 1 to i-1
                    selectObject: cs_list
                    previous_cs$ = Get string: j
                    if length(previous_cs$) >= 16
                        if left$(previous_cs$, 16) = sid$
                            seen_before = 1
                        endif
                    endif
                endfor
            endif
            if seen_before = 0
                cs_count = 0
                sv_count = 0
                cs_files$ = ""
                sv_files$ = ""
                for j from 1 to number_of_cs
                    selectObject: cs_list
                    candidate$ = Get string: j
                    if length(candidate$) >= 16
                        if left$(candidate$, 16) = sid$
                            cs_count = cs_count + 1
                            if cs_files$ = ""
                                cs_files$ = candidate$
                            else
                                cs_files$ = cs_files$ + "; " + candidate$
                            endif
                        endif
                    endif
                endfor
                for k from 1 to number_of_sv
                    selectObject: sv_list
                    candidate$ = Get string: k
                    if length(candidate$) >= 16
                        if left$(candidate$, 16) = sid$
                            sv_count = sv_count + 1
                            if sv_files$ = ""
                                sv_files$ = candidate$
                            else
                                sv_files$ = sv_files$ + "; " + candidate$
                            endif
                        endif
                    endif
                endfor
                if cs_count <> 1 or sv_count <> 1
                    preflight_errors = preflight_errors + 1
                    problem$ = "Expected exactly 1 CS and 1 SV"
                    preflight_tsv$ = preflight_tsv$ + sid$ + tab$ + string$(cs_count) + tab$ + string$(sv_count) + tab$ + cs_files$ + tab$ + sv_files$ + tab$ + problem$ + newline$
                    preflight_text$ = preflight_text$ + "SampleID " + sid$ + ": CS=" + string$(cs_count) + ", SV=" + string$(sv_count) + newline$
                    if cs_files$ = ""
                        preflight_text$ = preflight_text$ + "  CS: (none)" + newline$
                    else
                        preflight_text$ = preflight_text$ + "  CS: " + cs_files$ + newline$
                    endif
                    if sv_files$ = ""
                        preflight_text$ = preflight_text$ + "  SV: (none)" + newline$
                    else
                        preflight_text$ = preflight_text$ + "  SV: " + sv_files$ + newline$
                    endif
                endif
            endif
        endif
    endfor

    # Check SV filenames shorter than 16 characters and SampleIDs absent from CS.
    for k from 1 to number_of_sv
        selectObject: sv_list
        sv_name$ = Get string: k
        if length(sv_name$) < 16
            preflight_errors = preflight_errors + 1
            preflight_tsv$ = preflight_tsv$ + "" + tab$ + "0" + tab$ + "1" + tab$ + "" + tab$ + sv_name$ + tab$ + "SV filename has fewer than 16 characters" + newline$
            preflight_text$ = preflight_text$ + "SV filename <16 characters: " + sv_name$ + newline$
        else
            sid$ = left$(sv_name$, 16)
            seen_before = 0
            if k > 1
                for j from 1 to k-1
                    selectObject: sv_list
                    previous_sv$ = Get string: j
                    if length(previous_sv$) >= 16
                        if left$(previous_sv$, 16) = sid$
                            seen_before = 1
                        endif
                    endif
                endfor
            endif
            if seen_before = 0
                cs_count = 0
                sv_count = 0
                cs_files$ = ""
                sv_files$ = ""
                for j from 1 to number_of_cs
                    selectObject: cs_list
                    candidate$ = Get string: j
                    if length(candidate$) >= 16
                        if left$(candidate$, 16) = sid$
                            cs_count = cs_count + 1
                            if cs_files$ = ""
                                cs_files$ = candidate$
                            else
                                cs_files$ = cs_files$ + "; " + candidate$
                            endif
                        endif
                    endif
                endfor
                for j from 1 to number_of_sv
                    selectObject: sv_list
                    candidate$ = Get string: j
                    if length(candidate$) >= 16
                        if left$(candidate$, 16) = sid$
                            sv_count = sv_count + 1
                            if sv_files$ = ""
                                sv_files$ = candidate$
                            else
                                sv_files$ = sv_files$ + "; " + candidate$
                            endif
                        endif
                    endif
                endfor
                if cs_count = 0
                    preflight_errors = preflight_errors + 1
                    problem$ = "No corresponding CS"
                    preflight_tsv$ = preflight_tsv$ + sid$ + tab$ + "0" + tab$ + string$(sv_count) + tab$ + "" + tab$ + sv_files$ + tab$ + problem$ + newline$
                    preflight_text$ = preflight_text$ + "SampleID " + sid$ + ": CS=0, SV=" + string$(sv_count) + newline$
                    preflight_text$ = preflight_text$ + "  CS: (none)" + newline$
                    preflight_text$ = preflight_text$ + "  SV: " + sv_files$ + newline$
                endif
            endif
        endif
    endfor

    if preflight_errors > 0
        writeFile: preflight_file$, preflight_tsv$
        clearinfo
        writeInfoLine: "ARI v1.2.0"
        appendInfoLine: "Mode: Batch"
        appendInfoLine: ""
        appendInfoLine: "Preflight FAILED. Analysis was not started."
        appendInfoLine: "Problems found: ", preflight_errors
        appendInfoLine: ""
        appendInfoLine: preflight_text$
        appendInfoLine: "Preflight report: ", preflight_file$
        removeObject: cs_list, sv_list
        exitScript: "Correct the CS/SV file pairing and run ARI again."
    endif

    call prepareOutputFiles

    total_pairs = number_of_cs
    success_count = 0
    failure_count = 0

    # Preflight passed. Each CS has exactly one corresponding SV.
    for m12_pair_index from 1 to number_of_cs
        selectObject: cs_list
        cs_file_name$ = Get string: m12_pair_index
        sampleid$ = left$(cs_file_name$, 16)
        sv_file_name$ = ""
        for k from 1 to number_of_sv
            selectObject: sv_list
            candidate$ = Get string: k
            if left$(candidate$, 16) = sampleid$
                sv_file_name$ = candidate$
            endif
        endfor

        cs_file_path$ = batch_cs_folder$ + "/" + cs_file_name$
        sv_file_path$ = batch_sv_folder$ + "/" + sv_file_name$
        marker_file$ = output_folder$ + "/ARI_success_" + fixed$(m12_pair_index, 0) + ".tmp"
        stage_file$ = output_folder$ + "/ARI_stage_" + fixed$(m12_pair_index, 0) + ".tmp"
        if fileReadable(marker_file$)
            deleteFile: marker_file$
        endif
        if fileReadable(stage_file$)
            deleteFile: stage_file$
        endif

        # Overwrite the Info window for each case so the current progress remains
        # visible without a growing scrollback history.
        clearinfo
        writeInfoLine: "ARI v1.2.0"
        appendInfoLine: "Mode: Batch"
        appendInfoLine: ""
        appendInfoLine: "Preflight: passed"
        appendInfoLine: "Valid pairs: ", total_pairs
        appendInfoLine: ""
        appendInfoLine: "Progress: ", m12_pair_index, " / ", total_pairs
        appendInfoLine: "Completed: ", m12_pair_index-1
        appendInfoLine: "Remaining: ", total_pairs-m12_pair_index+1
        appendInfoLine: ""
        appendInfoLine: "SampleID: ", sampleid$
        appendInfoLine: "CS: ", cs_file_name$
        appendInfoLine: "SV: ", sv_file_name$
        appendInfoLine: ""
        appendInfoLine: "Status: Analyzing..."

        sample_id$ = sampleid$
        run_mode$ = "Batch"
        pair_index = m12_pair_index
        call analyzePair

        if fileReadable(marker_file$)
            success_count = success_count + 1
            deleteFile: marker_file$
        else
            failure_count = failure_count + 1
            failure_stage$ = "Analysis failed before completion."
            if fileReadable(stage_file$)
                failure_stage$ = replace$(readFile$(stage_file$), newline$, "", 0)
            endif
            appendFileLine: analysis_log_file$, "Batch", tab$, string$(m12_pair_index), tab$, string$(total_pairs), tab$, sampleid$, tab$, cs_file_name$, tab$, sv_file_name$, tab$, "ERROR", tab$, "", tab$, "", tab$, failure_stage$
        endif
        if fileReadable(stage_file$)
            deleteFile: stage_file$
        endif

        # analyzePair performs its own safe cleanup. It preserves everything
        # that existed before the pair started, including the user's objects
        # and the two batch file-list objects.
    endfor

    removeObject: cs_list, sv_list
    appendFileLine: analysis_log_file$, "Batch", tab$, "SUMMARY", tab$, string$(total_pairs), tab$, "", tab$, "", tab$, "", tab$, "Completed", tab$, string$(success_count), tab$, string$(failure_count), tab$, "Succeeded / Failed"

    clearinfo
    writeInfoLine: "ARI v1.2.0"
    appendInfoLine: "Mode: Batch"
    appendInfoLine: ""
    appendInfoLine: "Analysis completed."
    appendInfoLine: "Total pairs: ", total_pairs
    appendInfoLine: "Succeeded: ", success_count
    appendInfoLine: "Failed: ", failure_count
    appendInfoLine: ""
    appendInfoLine: "Results: ", result_file$
    appendInfoLine: "Log: ", analysis_log_file$

    # Explicit completion dialog so unattended Batch runs are obvious when finished.
    beginPause: "ARI v1.2.0 - Batch completed"
        comment: "Batch analysis completed."
        comment: "Total pairs: " + string$(total_pairs)
        comment: "Succeeded: " + string$(success_count)
        comment: "Failed: " + string$(failure_count)
        comment: "Results: " + result_file$
        comment: "Log: " + analysis_log_file$
    endPause: "OK", 1, 1
endif

########################################################################
# Initialize result/log files after validation or preflight.
procedure prepareOutputFiles
    if overwrite_result_file
        if fileReadable(result_file$)
            deleteFile: result_file$
        endif
        if fileReadable(analysis_log_file$)
            deleteFile: analysis_log_file$
        endif
    endif
    if not fileReadable(result_file$)
        writeFileLine: result_file$, header$
    endif
    if not fileReadable(analysis_log_file$)
        writeFileLine: analysis_log_file$, log_header$
    endif
endproc

########################################################################

########################################################################
# Analysis core contained in this single script.
procedure analyzePair
########################################################################

save_directory$ = output_folder$
writeFileLine: stage_file$, "Preparing input Sounds"
####################The settings are locked###########################
#comment ▼SubharmonicsDraw frames to search
  draw_subh_search_frame = 0
#comment ▼Frame length, Distance between frame centres
frame_length = 0.1
time_step = 0.0033
#comment ▼Unified average intensity of samples
intensity_resample = 1
 avg_int = 70

#=comment ▼Differential value of dB judged as a silent frame
 noLoud_lower_than_allsample = 30
#comment ▼Differential values of dB determined as frames containing harmonics
 noHarmonics_lower_than_frame = 20


#comment ▼DualOscillator peak threshold (dB)
biphonationPeakdBthreshold = 5
subharmonic3PeakdBthreshold = 5
subharmonic2PeakdBthreshold = 5
####################The settings are locked###########################

# Preserve every object that existed before this analysis procedure started.
# This includes all user objects and the batch file-list objects.
select all
ari_preexisting_ids# = selected# ()

d = 10
dd = 10
ddd = 10

# ----------------------------------------------------------------------
# Obtain and preprocess one explicitly supplied CS/SV pair.
# Single mode uses existing Sound objects selected by Object No.
# Batch mode reads the strictly preflight-matched files from disk.
# No filename-matching rule is applied inside this analysis procedure.
# ----------------------------------------------------------------------
if run_mode$ = "Single"
    selectObject: single_cs_object_id
    name1$ = selected$("Sound")
else
    Read from file: cs_file_path$
    name1$ = selected$("Sound")
    if cs_file_name$ = ""
        cs_file_name$ = name1$ + ".wav"
    endif
endif
sampleRate = Get sampling frequency
if sampleRate <> 44100
    Resample: 44100, 50
    Rename: name1$
endif
ch = Get number of channels
if ch <> 1
    Extract one channel: 1
    Rename: name1$
endif
ari_cs_work_id = selected("Sound")

if run_mode$ = "Single"
    selectObject: single_sv_object_id
    name2$ = selected$("Sound")
else
    Read from file: sv_file_path$
    name2$ = selected$("Sound")
    if sv_file_name$ = ""
        sv_file_name$ = name2$ + ".wav"
    endif
endif
sampleRate = Get sampling frequency
if sampleRate <> 44100
    Resample: 44100, 50
    Rename: name2$
endif
ch = Get number of channels
if ch <> 1
    Extract one channel: 1
    Rename: name2$
endif

# Create a final SV working object after CS preprocessing in every case.
# >3 s: central 3 s. <=3 s: whole SV copied unchanged.
durationVowel = Get total duration
durationStart = durationVowel/2 - 1.5
durationEnd = durationVowel/2 + 1.5
if durationVowel > 3
    Extract part... durationStart durationEnd rectangular 1 no
    Rename... 'name2$'
else
    Copy... 'name2$'_part
    Rename... 'name2$'
endif
ari_sv_work_id = selected("Sound")

# The final SV working object is always created after the CS working object,
# so Praat's Objects-list concatenation order is consistently CS -> SV.
selectObject: ari_cs_work_id
plusObject: ari_sv_work_id
Concatenate
Rename: "simpleCHAIN"

# Display identifier used in the figure. Single mode permits a blank SampleID.
namecs$ = sample_id$
if namecs$ = ""
    namecs$ = name1$
endif

writeFileLine: stage_file$, "Running ARI/ABI analysis"
Font size... 8
selectObject: "Sound simpleCHAIN"
sounddefo = selected("Sound")
namedefo$ = selected$("Sound")

duration = Get total duration
x = frame_length
n = floor((duration-frame_length)/time_step)+2

#pauseScript: "namedefo$ = ", namedefo$


#################################################################
#################################################################
###############↓↓↓↓ fo estimation by SFEEDS↓↓↓↓ ######################
#################################################################
#################################################################

#######Unify the average INTENSITY of the sample with avg_int########################
#Default is to resample Intensity
if intensity_resample = 1
Scale intensity: avg_int
endif


#######Calculate the mean fo of the sample####################
# Create a long-term average spectrum.
To Spectrum... yes
To Ltas (1-to-1)

#Find the spectral maximum peak for the entire sample (to be used as a comparison during silence evaluation).
sample_all_dB = Get maximum... 0 0 none

selectObject: "Spectrum 'namedefo$'"
plusObject: "Ltas 'namedefo$'"
call ariSafeRemove


#################################################################
#################### Beginning of overall delineation (0-1000Hz)　######################
#################################################################
Erase all

selectObject: sounddefo
To Pitch (ac): 0, 75, 15, "no", 0.03, 0.45, 0.01, 0.35, 0.14, 600
Rename... 'namedefo$'_1


if draw_Figure = 1
#Spectrograms up to 1000 Hz are drawn.  
Line width... 1
do ("Select outer viewport...", 0, 10, 0.2, 8)
select Sound 'namedefo$'
    To Spectrogram... 0.1 1000 0.002 2 Gaussian
　　    Black
      Paint... 0 0 0 0 100 yes 50 0 0 yes
    #Text: duration/2, "centre", 1020, "half", "'namecs16$'"
　   Text: 0, "right", 100, "half", "100"
　　Red
    Text: duration*3/4, "centre", -20, "half", "fo is estimated by SFEEDS"

    ######################Drawing spectrograms and enclosures###############################
do ("Select outer viewport...", 0, 10, 0.2, 8)
    Black
    Line width... 0.5
   　select Pitch 'namedefo$'_1
     Formula: "0"
   　Draw... 0 0 0 1000 no

select Pitch 'namedefo$'_1
plus Spectrogram 'namedefo$'
call ariSafeRemove
endif
#################################################################
################ End of overall delineation.　###################
#################################################################



#################################################################
#########Start of frame-by-frame calculation and delineation.　　############
#################################################################


#######　Create files for frame analysis (Gaussian window ). ###############
##### x is the frame length #####
####  n is the number of frames ########
##### x*n = number of seconds available for analysis ##########


for number from 1 to 'n'
　　selectObject: sounddefo
   Extract part: (number-1)*'time_step', x+(number-1)*'time_step', "Gaussian1", 1, "no"
   Rename: "'namedefo$'_'number'"
endfor

############Start of frame-by-frame circulation.#################
#################################################################

for i from 1 to 'n'
selectObject: "Sound 'namedefo$'_'i'"

sound = selected("Sound")
name$ = selected$ ("Sound")

To Ltas: 6

#Find the maximum spectral peak in the frame.
frame_all_dB = Get maximum... 0 0 none


h_defo_dB = Get maximum... 50 400 none
h_defo_Hz = Get frequency of maximum... 50 400 none


for z from 2 to 7
h_'z'_dB = Get maximum... (z-1)/8*h_defo_Hz z/8*h_defo_Hz None
h_'z'_Hz = Get frequency of maximum... (z-1)/8*h_defo_Hz z/8*h_defo_Hz None
endfor

#################################################################
################### Dominant Spectrum Test　######################
#################################################################

#Select the fundamental frequency from these spectral peaks
#If the difference between the highest spectral peak and the highest spectral peak is within d(dB), the structure is recognised as an harmonics structure.
#In order from the lowest frequency.
#Adopt larger peaks in adjacent search ranges

if h_2_dB > h_defo_dB - d  and   h_2_dB > h_3_dB
  h1_Hz = h_2_Hz
  h1_dB = h_2_dB
elsif h_2_dB > h_defo_dB - d  and   h_2_dB < h_3_dB
  h1_Hz = h_3_Hz
  h1_dB = h_3_dB

elsif h_3_dB > h_defo_dB - d  and   h_3_dB > h_4_dB
  h1_Hz = h_3_Hz
  h1_dB = h_3_dB
elsif h_3_dB > h_defo_dB - d  and   h_3_dB < h_4_dB
  h1_Hz = h_4_Hz
  h1_dB = h_4_dB

elsif h_4_dB > h_defo_dB - d  and   h_4_dB > h_5_dB
  h1_Hz = h_4_Hz
  h1_dB = h_4_dB
elsif h_4_dB > h_defo_dB - d  and   h_4_dB < h_5_dB
  h1_Hz = h_5_Hz
  h1_dB = h_5_dB

elsif h_5_dB > h_defo_dB - d   and   h_5_dB > h_6_dB
  h1_Hz = h_5_Hz
  h1_dB = h_5_dB
elsif h_5_dB > h_defo_dB - d   and   h_5_dB < h_6_dB
  h1_Hz = h_6_Hz
  h1_dB = h_6_dB

elsif h_6_dB > h_defo_dB - d  and   h_6_dB > h_7_dB
  h1_Hz = h_6_Hz
  h1_dB = h_6_dB
elsif h_6_dB > h_defo_dB - d  and   h_6_dB < h_7_dB
  h1_Hz = h_7_Hz
  h1_dB = h_7_dB
 
elsif h_7_dB > h_defo_dB - d and h_7_dB > h_defo_dB
  h1_Hz = h_7_Hz
  h1_dB = h_7_dB

else
   h1_Hz = h_defo_Hz
   h1_dB = h_defo_dB
endif

  h1_score_'i' = h1_dB
  h1_Hz_'i' = h1_Hz

#################################################################
#################################################################
################ Sequential Spectrum Test　######################
#################################################################
#################################################################

#In the frequency band 1/10 around the frequency calculated in the previous frame (h1_Hz_'previous').
#If a frequency component with equivalent power (within ±1/10) and within ◯dB (noHarmonics_lower_than_frame) of the maximum spectrum in the frame is also present in this frame.
#The result of the Sequential Spectrum test is used as the frame frequency candidate in preference to the Dominant Spectrum test.
#In other words, when a continuous fo spectral structure cannot be confirmed between consecutive frames, such as at the start and end of a phrase or during a Pitch Jump, a new fo is detected by the Dominant Spectrum Test.

h1_Hz_0 = 0
h1_score_0 = 0
previous = i-1
previous2 = i-2
#appendInfoLine: previous
#appendInfoLine: h1_Hz_'previous'


######
if h1_Hz_'previous'<>0 
h_CompareWithPrevious_dB = Get maximum... 9/10*h1_Hz_'previous' 11/10*h1_Hz_'previous' None
h_CompareWithPrevious_Hz = Get frequency of maximum... 9/10*h1_Hz_'previous' 11/10*h1_Hz_'previous' None
#appendInfoLine: "previous_was_not0Hz"

if h_CompareWithPrevious_dB > h1_score_'previous' - dd and h_CompareWithPrevious_dB < h1_score_'previous' + dd and h_CompareWithPrevious_dB > frame_all_dB - noHarmonics_lower_than_frame 
  h1_score_'i' = h_CompareWithPrevious_dB
  h1_Hz_'i' = h_CompareWithPrevious_Hz

else
 #
endif

else
 #
endif




#################################################################
#################################################################
############# Dominant Spectrum Test　Completed ##################
############# Sequential Spectrum Test　Completed ################
#################################################################
#################################################################




################Search above and below the candidate frequency (h1_Hz_'i') in the frame####################
########################Correction if 2fo is mis-detected.####################################
###
# 1.5 times Hz of the extracted frequency
h_search15_dB_'i' = Get maximum... 1.5*h1_Hz_'i'-10 1.5*h1_Hz_'i'+10 None
h_search15_Hz_'i' = Get frequency of maximum... 1.5*h1_Hz_'i'-10 1.5*h1_Hz_'i'+10 None

# 0.5 times Hz of the extracted frequency
h_search05_dB_'i' = Get maximum... 1/2*h1_Hz_'i'-10 1/2*h1_Hz_'i'+10 None
h_search05_Hz_'i' = Get frequency of maximum... 1/2*h1_Hz_'i'-10 1/2*h1_Hz_'i'+10 None


#If 2fo is mis-detected, the spectral intensity should be fo≒2fo.
#If the spectrum with the lower (0.5x) intra-frame candidate frequency (h1_Hz_'i') is within ddd(db) of the peak difference with h1_score_'i' and is strong enough to be a valid overtone compared to the whole frame dB, then 2fo is mis-detected.
if h_search05_dB_'i' > h1_score_'i' - ddd and h_search05_dB_'i' > frame_all_dB - noHarmonics_lower_than_frame
  h1_score_'i' =   h_search05_dB_'i'
  h1_Hz_'i' =  h_search05_Hz_'i' 
endif


########################Correction if 1.5fo is mis-detected####################################
# 2/3 times Hz of the extracted frequency
h_search23_dB_'i' = Get maximum... 2/3*h1_Hz_'i'-10 2/3*h1_Hz_'i'+10 None
h_search23_Hz_'i' = Get frequency of maximum... 2/3*h1_Hz_'i'-10 2/3*h1_Hz_'i'+10 None

# If h_search23_dB is within ddd(db) of the peak difference from h1_score_'i' and is strong enough to be a valid overtone compared to the whole frame dB, 1.5 fo is corrected as mis-detected.
if  h_search23_dB_'i' > h1_score_'i' - ddd   and  h_search23_dB_'i' > frame_all_dB - noHarmonics_lower_than_frame
  h1_score_'i' =   h_search23_dB_'i'
  h1_Hz_'i' =  h_search23_Hz_'i' 
endif




###############################################################


#▲Frames that are lower than the maximum dB of the entire sample by more than ◯dB (noLoud_lower_than_allsample) are set to 0 dB as "silent".
if  h1_score_'i' < sample_all_dB - noLoud_lower_than_allsample
  h1_score_'i' = 0
  h1_Hz_'i' = 0
endif

#Excludes recording noise and the low-frequency spectrum generated by speech tremor.
if h1_Hz_'i' <50
   h1_score_'i' = 0
  　h1_Hz_'i' = 0
endif


#################################################################
if draw_Figure = 1

#Drawing extracted fo for each frame.
#The spectrum set to 0 above as too weak is not drawn in the Spectrogram.
if  h1_score_'i' > 0
do ("Select outer viewport...", 0, 10, 0.2, 8)
    Red
    Paint circle (mm): "red", time_step*(i-1)+frame_length/2, h1_Hz_'i', 0.6
endif

endif


#################################################################
#################################################################

#Remove unwanted files generated by frame analysis.
selectObject: "Ltas 'name$'"
call ariSafeRemove


 bin_f0PeakdB_'i' = h1_score_'i' 
 bin_f0PeakHz_'i' = h1_Hz_'i'

endfor


#################################################################
############ End of frame-by-frame delineation.　################
#################################################################







#################################################################
#################################################################
###############↑↑↑↑ fo estimation by SFEEDS↑↑↑↑ ######################
#################################################################
#################################################################

#pause  stop
#goto testSFEEDS

#################################################################
#################################################################
######Assign h1_score_'i' and h1_Hz_'i' to all frames　   #######
#################################################################
#################################################################

#for i from 1 to 'n'
#appendInfoLine: "",h1_Hz_'i'," 　　　",h1_score_'i'," "
#endfor


#################################################################
#################################################################
#################################################################
#################################################################
#################################################################
#################################################################
###########↓↓↓↓ Subharmonics Quantification↓↓↓↓ #################
#################################################################
#################################################################
#################################################################
#################################################################
#################################################################
#################################################################

# If time_step = 0.0033sec, search subharmonics at intervals of d times (e.g., 0.0033*40 = 0.123sec for 40 times)

#If all frames (n) are equally divided by (div), the calculation is limited to (divcount) frames only
divd = 20
divcount = floor(n/divd)

#Subharmonics search window is drawn in black on the spectrogram. 
#Note that here, a new frame number ii is assigned for the subharmonics search.
#Note here that the ii th frame corresponds to the ii*d th frame of the original!
if draw_Figure = 1
if draw_subh_search_frame = 1
for ii from 1 to 'divcount'
do ("Select outer viewport...", 0, 10, 0.2, 8)
    Black
    Paint rectangle: 0.1, time_step*(divd*ii-1), time_step*(divd*ii-1)+frame_length, 0, 10   
#　　　　　　　　　Text: time_step*(divd*ii-1)+frame_length/2, "centre", -10, "half", "'ii'"
endfor
endif
endif


#################################################################
#################################################################
#########↓↓↓↓Search at ii*divdth (= ssth) frame↓↓↓↓ ###############
#################################################################
#################################################################

#Subharmonics original frame number (ss-th) from which the extract is taken.
#for ii from 1 to 'divcount'
#ss = ii*divd
#  appendInfoLine: ii*40
#  appendInfoLine: h1_db_'ss'
#endfor



#################################################################
##### Leave only equally spaced frames sorted for Subharmonics testing　#######
#################################################################


for ii from 1 to 'divcount'
ss = ii*divd
　#Subharmonics original frame number (ssth) extracted at equal intervals (divd skipped).

selectObject: "Sound 'namedefo$'_'ss'"
　#Lats (bins every 6Hz) created for every frame
　#0.1sec frame does not allow for more detailed spectral frequency analysis
To Ltas: 6
　#Assign a serial number (ii=1~divcountth) to SubhSearchFrame
　#The iith SubhSearchFrame corresponds to the original frame ss(ii*40)th.
Rename: "'namedefo$'_SubhSearchFrame_'ii'"
endfor



##Delete all original frames, leaving only the Ltas of SubhSearchFrame
selectObject: "Sound 'namedefo$'_1"
for number from 2 to 'n'
plusObject: "Sound 'namedefo$'_'number'"
endfor
call ariSafeRemove


#################################################################
#################################################################
#################################################################
#################################################################
##### Subharmonics search starts for each SubhSearchFrame.　#####
###Sequential numbers (ii=1~divcountth) are assigned to SubhSearchFrame.　###
###The ii-th SubhSearchFrame corresponds to the original frame ss(ii*40)th###
#################################################################
#################################################################
#################################################################
#################################################################


for ii from 1 to 'divcount'
ss = ii*divd

selectObject: "Ltas 'namedefo$'_SubhSearchFrame_'ii'"



#Classify each SubhSearchFrame into the following Subh
 #subhType_'ii' = 0 :　Default state, adapted in the silent part
 #subhType_'ii' = 1 :　Default state, adapted in the silent part
 #subhType_'ii' = 2 :　Frame in which 1/2Subharmonics exists 　　(3)Test order
 #subhType_'ii' = 3 :　Frames with 1/3~1/4Subharmonic　　　　　　 (2) Test order
 #subhType_'ii' = 4 :  Frames with more than one SuperSubharmonics   (1) Test order

subhType_'ii' = 0




#These variables are reset once before and set to 0 when circulation begins
 h1NOISEh2 = 0
 bin_BIPHOPeakdB = 0
 bin_BIPHOPeakHz = 0
 bin_SUBH3PeakdB = 0
 bin_SUBH3PeakHz = 0
 bin_SUBH2PeakdB = 0
 bin_SUBH2PeakHz = 0

 h1NOISEh2_rltv = 0
 bin_BIPHOrltvdB = 0
 bin_SUBH3rltvdB = 0
 bin_SUBH2rltvdB = 0


#If h1_score_'ss' > 0, then it is a silent part without Harmonics and no search is performed
if h1_score_'ss' = 0
goto noHARMONICS
endif



#################################################################
############ For calculation of h1NOISEh2__rltv　################
#################################################################

#Average noise in the middle 1/2
　h1NOISEh2 = Get mean: 5/4*h1_Hz_'ss', 7/4*h1_Hz_'ss', "energy" 
　h1NOISEh2_rltv  = h1_score_'ss' - h1NOISEh2
endif


#Only noise greater than 10 dB counted as audible
#if  h1NOISEh2_'i' > 10
#   h1NOISEh2_above10_'i' = h1NOISEh2_'i' - 10
#else 
#   h1NOISEh2_above10_'i' = 0
#endif


#################################################################
############ For examination by SUBHARMONICS Type　############## 
#################################################################



##############. Investigate one bin at a time from fo to 2fo　##################### 

#bin_f0 indicates the bin number where fo exists
bin_f0 = (h1_Hz_'ss'/6)+0.5
#appendInfoLine: bin_f0


for b from bin_f0 to 2*bin_f0
  bin_nexttof0_'b' = Get value in bin...  b
　#appendInfoLine: bin_nexttof0_'b'
endfor




#If the detected f0 is too small to calculate the low frequency bin, only the result of h1NOISEh2 is reflectedる
#f0 < approx. 11.5 bin = approx. 70 Hz
if bin_f0 > floor(23/16*bin_f0)-5
  goto tooLowfo
endif
 



#①
#BIPHONATION (BIPHO)
#Tests SuperSubharmonics with peaks in the range from f0 to less than 5/4f0
#Search until 4 bins of (b-3)~b form a peak (peak is b-2) above the biphonationPeakdBthreshold (default is 5) dB
#Requirement that b2-b3 or b2-b4 or b2-b5 be greater
#Furthermore, if the peak of the mountain is within 20 dB of the dB of f0 and the difference value, BIPHONATION
for b from bin_f0+5 to round(5/4*bin_f0)+2
#where b is the beginning of the 5-sequence bin to be searched
b5 = b-5
b4 = b-4
b3 = b-3
b2 = b-2
b1 = b-1
b0 = b
if bin_nexttof0_'b3' < bin_nexttof0_'b2' and bin_nexttof0_'b2' > bin_nexttof0_'b1' and bin_nexttof0_'b1' > bin_nexttof0_'b0' and  (bin_nexttof0_'b2'-bin_nexttof0_'b5' >biphonationPeakdBthreshold or bin_nexttof0_'b2'-bin_nexttof0_'b4' >biphonationPeakdBthreshold or bin_nexttof0_'b2'-bin_nexttof0_'b3' >biphonationPeakdBthreshold and bin_nexttof0_'b2'-bin_nexttof0_'b0'>biphonationPeakdBthreshold) and bin_nexttof0_'b2' > h1_score_'ss' - 20
 bin_BIPHOPeakNo = b-2 
 bin_BIPHOPeakdB = Get value in bin...  bin_BIPHOPeakNo
 bin_BIPHOPeakHz = (bin_BIPHOPeakNo-0.5)*6 
 bin_BIPHOrltvdB = h1_score_'ss' - bin_BIPHOPeakdB
 subhType_'ii' = 4
 goto biphonationDetected
endif
endfor


#②
#1/4or1/3 SUBHARMONIC
#Subharmonics with peaks in the range 5/4f0 to 23/16f0 (total 3/16) are tested
#Search until 7 bins of (bb-6)~bb form a peak (peak is bb-3) above subharmonic3PeakdBthreshold (default is 5) dB
#Furthermore, if the peak of the mountain is within 25 dB of the dB of f0 and the difference value, then 1/3Subharmonics
for bb from floor(5/4*bin_f0)+3 to round(23/16*bin_f0)+2
bb6 = bb-6
bb5 = bb-5
bb4 = bb-4
bb3 = bb-3
bb2 = bb-2
bb1 = bb-1
bb0 = bb

if bin_nexttof0_'bb5' < bin_nexttof0_'bb4' and bin_nexttof0_'bb4' < bin_nexttof0_'bb3' and bin_nexttof0_'bb3' > bin_nexttof0_'bb2' and bin_nexttof0_'bb2' > bin_nexttof0_'bb1' and bin_nexttof0_'bb1' > bin_nexttof0_'bb0' and  (bin_nexttof0_'bb3'-bin_nexttof0_'bb6' >subharmonic3PeakdBthreshold or bin_nexttof0_'bb3'-bin_nexttof0_'bb5' >subharmonic3PeakdBthreshold and bin_nexttof0_'bb3'-bin_nexttof0_'bb0'>subharmonic3PeakdBthreshold) and bin_nexttof0_'bb3' > h1_score_'ss' - 25
 bin_SUBH3PeakNo = bb-3 
 bin_SUBH3PeakdB = Get value in bin...  bin_SUBH3PeakNo
 bin_SUBH3PeakHz = (bin_SUBH3PeakNo-0.5)*6 
 bin_SUBH3rltvdB = h1_score_'ss' - bin_SUBH3PeakdB
 subhType_'ii' = 3
 goto subharmonic3Detected
endif
endfor




#③
#1/2SUBHARMONIC
#Test for subharmonics with peaks in the range 23/16f0 to 25/16f0 (middle 1/8 of f0 and 2f0)
#Search until 7 bins of (bbb-6)~bbb form a peak (peak is bbb-3) above subharmonic2PeakdBthreshold (default is 5) dB
#Furthermore, if the peak of the mountain is within 25 dB of the dB of f0 and the difference value, then 1/2Subharmonics
for bbb from round(23/16*bin_f0)+2 to round(25/16*bin_f0)+3
bbb6 = bbb-6
bbb5 = bbb-5
bbb4 = bbb-4
bbb3 = bbb-3
bbb2 = bbb-2
bbb1 = bbb-1
bbb0 = bbb

h2_NarrowMax = Get maximum... (16*2-1)/16*h1_Hz_'ss' (16*2+1)/16*h1_Hz_'ss' none
searchFORsubh2mindB = Get minimum... 26/16*h1_Hz_'ss' 7/4*h1_Hz_'ss' none
searchFORsubh2thresholddB = (h1_score_'ss' + h2_NarrowMax)/2

if bin_nexttof0_'bbb6' < bin_nexttof0_'bbb5' and bin_nexttof0_'bbb5' < bin_nexttof0_'bbb4' and bin_nexttof0_'bbb4' < bin_nexttof0_'bbb3' and bin_nexttof0_'bbb3' > bin_nexttof0_'bbb2' and bin_nexttof0_'bbb2' > bin_nexttof0_'bbb1' and bin_nexttof0_'bbb1' > bin_nexttof0_'bbb0' and  (bin_nexttof0_'bbb3'-bin_nexttof0_'bbb6' >subharmonic2PeakdBthreshold or bin_nexttof0_'bbb3'-bin_nexttof0_'bbb0'>subharmonic2PeakdBthreshold) and bin_nexttof0_'bbb3' > h1_score_'ss' - 25  
#if bin_nexttof0_'bbb6' < bin_nexttof0_'bbb5' and bin_nexttof0_'bbb5' < bin_nexttof0_'bbb4' and bin_nexttof0_'bbb4' < bin_nexttof0_'bbb3' and bin_nexttof0_'bbb3' > bin_nexttof0_'bbb2' and bin_nexttof0_'bbb2' > bin_nexttof0_'bbb1' and bin_nexttof0_'bbb1' > bin_nexttof0_'bbb0' and  (bin_nexttof0_'bbb3'-bin_nexttof0_'bbb6' >subharmonic2PeakdBthreshold or bin_nexttof0_'bbb3'-bin_nexttof0_'bbb0'>subharmonic2PeakdBthreshold) and bin_nexttof0_'bbb3' > h1_score_'ss'/4   and bin_SUBH2PeakdB - searchFORsubh2mindB > 10 and searchFORsubh2thresholddB - bin_SUBH2PeakdB < 30

 bin_SUBH2PeakNo = bbb-3 
 bin_SUBH2PeakdB = Get value in bin...  bin_SUBH2PeakNo
 bin_SUBH2PeakHz = (bin_SUBH2PeakNo-0.5)*6 
 bin_SUBH2rltvdB = h1_score_'ss' - bin_SUBH2PeakdB
 subhType_'ii' = 2
 goto subharmonic2Detected
endif
endfor


#④
#Only if all of the Super, 1/3, and 1/2 Subharmonics are not present, or if f0 is too small to calculate the low frequency bin
#Frames containing Harmonics arrive here
label tooLowfo
subhType_'ii' = 1



##########　SubharmonicsSearchFrame毎のSubharmonics検定後のジャンプ先
label noHARMONICS
label biphonationDetected
label subharmonic3Detected
label subharmonic2Detected


#SubharmonicsSearchFrame ii.
#SubharmonicsType is assigned a value by SubharmonicsType.
 h1NOISEh2_'ii' =  h1NOISEh2
 bin_BIPHOPeakdB_'ii'　= bin_BIPHOPeakdB
 bin_BIPHOPeakHz_'ii' =  bin_BIPHOPeakHz
 bin_SUBH3PeakdB_'ii' =  bin_SUBH3PeakdB
 bin_SUBH3PeakHz_'ii' =  bin_SUBH3PeakHz
 bin_SUBH2PeakdB_'ii' =  bin_SUBH2PeakdB
 bin_SUBH2PeakHz_'ii' =  bin_SUBH2PeakHz

 h1NOISEh2_rltv_'ii'  =  h1NOISEh2_rltv
 bin_BIPHOrltvdB_'ii' =  bin_BIPHOrltvdB 
 bin_SUBH3rltvdB_'ii' =  bin_SUBH3rltvdB
 bin_SUBH2rltvdB_'ii' =  bin_SUBH2rltvdB


endfor
#The for syntax for each SubharmonicsSearchFrame is closed here.




############### Detects cases where the SubharmonicsSearchFrame result matches two consecutive frames　##################
 #If two adjacent SubhSearchFrames are classified as the same Subh, they are determined as the same Subh.
 #subhTypeFin_'ii' = 0 :　 Default state 
 #subhTypeFin_'ii' = 1 :　Frames with ChaoticNoise (Harmonics frames without Subharmonics below)
 #subhTypeFin_'ii' = 2 :　Frame with 1/2Subharmonics present　　　　　　 
 #subhTypeFin_'ii' = 3 :　Frames with 1/3~1/4Subharmonic present　　 
 #subhTypeFin_'ii' = 4 :  Frames with more SuperSubharmonics than that  

#Once all frames are set to default
for ii from 1 to 'divcount'
 subhTypeFin_'ii' = 0  
endfor



for ii from 1 to 'divcount'-1
iii = ii+1
 if subhType_'ii' = subhType_'iii'　and (  abs(bin_BIPHOPeakHz_'ii'- bin_BIPHOPeakHz_'iii')<15  and  abs(bin_SUBH3PeakHz_'ii'- bin_SUBH3PeakHz_'iii')<15  and abs( bin_SUBH2PeakHz_'ii'-  bin_SUBH2PeakHz_'iii')<15 )
  subhTypeFin_'ii' = subhType_'ii'
  subhTypeFin_'iii' = subhType_'iii'
 elsif  subhType_'iii' = 1 or subhType_'iii' = 2 or subhType_'iii' = 3
   subhTypeFin_'iii' = 1
 endif
endfor



###############Subharmonics rendering in Spectrogram##################
for ii from 1 to 'divcount'
ss = ii*divd

if subhTypeFin_'ii' = 4
 Purple
    Line width... 3
    Draw line: time_step*(ss-1), bin_BIPHOPeakHz_'ii', time_step*(ss-1)+frame_length, bin_BIPHOPeakHz_'ii'
endif

if subhTypeFin_'ii' = 3
 Green
    Line width... 3
    Draw line: time_step*(ss-1), bin_SUBH3PeakHz_'ii', time_step*(ss-1)+frame_length, bin_SUBH3PeakHz_'ii'
endif

if subhTypeFin_'ii' = 2
 Cyan
    Line width... 3
    Draw line: time_step*(ss-1), bin_SUBH2PeakHz_'ii', time_step*(ss-1)+frame_length, bin_SUBH2PeakHz_'ii'
endif

if subhTypeFin_'ii' = 1
 Pink
    Line width... 3
    Draw line: time_step*(ss-1), 20, time_step*(ss-1)+frame_length, 20
endif


endfor


#################################################################
########## End of search for each SubharmonicsSearchFrame　##################
#################################################################




############################################################
############################################################
######## SubharmonicsSearchFrame frame analysis produced by SubharmonicsSearchFrame removes unwanted files. #######
############################################################
############################################################

selectObject: "Ltas 'namedefo$'_SubhSearchFrame_1"
for ii from 2 to 'divcount'
plusObject: "Ltas 'namedefo$'_SubhSearchFrame_'ii'"
endfor
call ariSafeRemove







#################################################################
#################################################################
#################################################################
#############↓↓↓↓ Subharmonics quantification↓↓↓↓ ###############
#################################################################
#################################################################
#################################################################



###########↓↓↓↓ Number and percentage of frames for which fo was detected in SubharmonicsSearchFrame　　↓↓↓↓ ############
#############################【frameHarmonics_SUM】#################################
##############################【percent_Harmonics】#################################

for ii from 1 to 'divcount'
ss = ii*divd
 if h1_score_'ss' = 0
   frameHarmonics_'ii' = 0
 else
   frameHarmonics_'ii' = 1
 endif
endfor

# Initialize variable (frameHarmonics_SUM) to store totals
frameHarmonics_SUM = 0
for ii from 1 to 'divcount'
   frameHarmonics_SUM += frameHarmonics_'ii'
endfor

# Output results
#appendInfoLine: "Total Harmonics: ", frameHarmonics_SUM
#appendInfoLine: "Total SubharmonicsSearchFrame: ", divcount

#Percentage of frames in the total sample that are accounted for by Harmonics (approximate)
percent_Harmonics = frameHarmonics_SUM/divcount*100
#appendInfoLine: "Total SubharmonicsSearchFrame(%): ", percent_Harmonics



###########################【frameChaoticNoise_SUM】#############################
###########################【percent_ChaoticNoise】#############################
########################【chaoticNoise_Power_of_all】#############################

for ii from 1 to 'divcount'
ss = ii*divd
 if subhTypeFin_'ii' = 1
   frameChaoticNoise_'ii' = 1
 else
   frameChaoticNoise_'ii' = 0
 endif
endfor

# Initialize variable (frameChaoticNoise_SUM) to store the total
frameChaoticNoise_SUM = 0
for ii from 1 to 'divcount'
   frameChaoticNoise_SUM += frameChaoticNoise_'ii'
endfor

# Output results
#appendInfoLine: "Total ChaoticNoise: ", frameChaoticNoise_SUM

#Percentage of frames in the entire sample that are ChaoticNoise (approximate)
percent_ChaoticNoise = frameChaoticNoise_SUM/divcount*100
#appendInfoLine: "Total SubharmonicsSearchFrame(%): ", percent_ChaoticNoise

#Relative ChaoticNoise power (dB) per frame (compared to f0)
#Initialize variable (frameChaoticNoise_Power_SUM) to store the total
frameChaoticNoise_Power_SUM = 0
for ii from 1 to 'divcount'
   frameChaoticNoise_Power_SUM += h1NOISEh2_rltv_'ii'
endfor

chaoticNoise_Power_per_frame = frameChaoticNoise_Power_SUM / frameChaoticNoise_SUM
chaoticNoise_Power_of_all = frameChaoticNoise_Power_SUM / frameHarmonics_SUM
#appendInfoLine: "ChaoticNoise_Power_per_frame(dB): ", chaoticNoise_Power_per_frame
#appendInfoLine: "ChaoticNoise_Power_of_all(dB): ", chaoticNoise_Power_of_all


###########################【frameSuperSubharmonics_SUM】#############################
########################【superSubharmonics_of_all】#############################
#####################【superSubharmonics_Power_of_all】#############################

for ii from 1 to 'divcount'
ss = ii*divd
 if subhTypeFin_'ii' = 4
   frameSuperSubharmonics_'ii' = 1
 else
   frameSuperSubharmonics_'ii' = 0
   bin_BIPHOrltvdB_'ii'  = 0
   bin_BIPHOPeakdB_'ii'  = 0
 endif
endfor

#Initialize variable (frameSuperSubharmonics_SUM) to store totals
frameSuperSubharmonics_SUM = 0
for ii from 1 to 'divcount'
   frameSuperSubharmonics_SUM += frameSuperSubharmonics_'ii'
endfor

#SuperSubharmonicsdB) relative to f0 per frame
#Initialize variable (superSubharmonics_Power_SUM) to store totals
superSubharmonics_Power_SUM = 0
for ii from 1 to 'divcount'
   superSubharmonics_Power_SUM += bin_BIPHOrltvdB_'ii'
endfor

 superSubharmonics_Power_of_all = superSubharmonics_Power_SUM / frameHarmonics_SUM



#Output results
#appendInfoLine: "Total SuperSubharmonics: ", frameSuperSubharmonics_SUM

superSubharmonics_of_all = frameSuperSubharmonics_SUM / frameHarmonics_SUM *100
#Output results
#appendInfoLine: "mean SuperSubharmonics(%): ", superSubharmonics_of_all



###########################【frame1_3rdSubharmonics_SUM】#############################
########################【one_3rdSubharmonics_of_all】#############################
####################【one_3rdSubharmonics_Power_of_all】#############################
for ii from 1 to 'divcount'
ss = ii*divd
 if subhTypeFin_'ii' = 3
   frame1_3rdSubharmonics_'ii' = 1
 else
   frame1_3rdSubharmonics_'ii' = 0
    bin_SUBH3PeakdB_'ii'  = 0
    bin_SUBH3rltvdB_'ii'  = 0
 endif
endfor

# Initialize variable (frame1_3rdSubharmonics_SUM) to store totals
frame1_3rdSubharmonics_SUM = 0
for ii from 1 to 'divcount'
   frame1_3rdSubharmonics_SUM += frame1_3rdSubharmonics_'ii'
endfor


#Relative value of one_3rdSubharmonicsdB) per frame (compared to f0)
#Initialize variable (one_3rdSubharmonics_Power_SUM) to store totals
one_3rdSubharmonics_Power_SUM = 0
for ii from 1 to 'divcount'
   one_3rdSubharmonics_Power_SUM += bin_SUBH3rltvdB_'ii'
endfor

 one_3rdSubharmonics_Power_of_all = one_3rdSubharmonics_Power_SUM / frameHarmonics_SUM



# Output results
#appendInfoLine: "Total 1/3Subharmonics: ", frame1_3rdSubharmonics_SUM

one_3rdSubharmonics_of_all = frame1_3rdSubharmonics_SUM / frameHarmonics_SUM *100
# Output results
#appendInfoLine: "mean 1/3Subharmonics(%): ", one_3rdSubharmonics_of_all


###########################【frame1_halfSubharmonics_SUM】#############################
########################【one_halfSubharmonics_of_all】#############################
#####################【 one_halfSubharmonics_Power_of_all】#############################
for ii from 1 to 'divcount'
ss = ii*divd
 if subhTypeFin_'ii' = 2
   frame1_halfSubharmonics_'ii' = 1
 else
   frame1_halfSubharmonics_'ii' = 0
   bin_SUBH2PeakdB_'ii'  = 0
   bin_SUBH2rltvdB_'ii'  = 0
 endif
endfor

# Initialize variable (frame1_halfSubharmonics_SUM) to store the total
frame1_halfSubharmonics_SUM = 0
for ii from 1 to 'divcount'
   frame1_halfSubharmonics_SUM += frame1_halfSubharmonics_'ii'
endfor


#Relative value of one_halfSubharmonicsdB) per frame (compared to f0)
# Initialize variable (one_halfSubharmonics_Power_SUM) to store totals
one_halfSubharmonics_Power_SUM = 0
for ii from 1 to 'divcount'
   one_halfSubharmonics_Power_SUM += bin_SUBH2rltvdB_'ii'
endfor

 one_halfSubharmonics_Power_of_all = one_halfSubharmonics_Power_SUM / frameHarmonics_SUM



# Output results
#appendInfoLine: "Total 1/2Subharmonics: ", frame1_halfSubharmonics_SUM

one_halfSubharmonics_of_all = frame1_halfSubharmonics_SUM / frameHarmonics_SUM *100
# Output results
#appendInfoLine: "mean 1/2Subharmonics(%): ", one_halfSubharmonics_of_all




#################################################################
############## Start drawing calculation results to Innner Viewport　#################
#################################################################
if draw_Figure = 1
# Perform initial setup
Solid line
Line width... 1
Black
Helvetica

# Set viewport to display title and researcher information
Font size... 5
Select inner viewport... 0 10 0 0.2
Axes... 0 10 0 10
Text... 0.7 Left 0 Half Script: Itsuki Kitayama and Kiyohito Hosokawa

# Show title
Font size... 12
Select inner viewport... 0 10 0 0.3
Axes... 0 10 0 10
Text... 0.7 Left 0 Half ##ACOUSTIC ROUGHNESS INDEX (ARI)#

# The part displaying patient information (commented out)
Font size... 12
Select inner viewport... 0 10 0 0.3
Axes... 0 10 0 10
Text... 9 Right 0 Half ##'namecs$'#

# Oscillogram
Select inner viewport... 0.5 9.5 8 9
selectObject: "Sound simpleCHAIN"
Draw... 0 0 0 0 no Curve
Draw inner box
endif

selectObject: "Sound simpleCHAIN"
call ariSafeRemove



#########################################################################
################　Calculation of other acoustic indices　##########################
#########################################################################
#########################################################################

#goto without_others


# --------------------------------------------------------------------------------------------
# PART 0:
# HIGH-PASS FILTERING OF THE SOUND FILES. 
#CRemove spectrum (fluctuation and other elements) below 34 Hz in S-files
# --------------------------------------------------------------------------------------------

#■Select CS Sample
selectObject: ari_cs_work_id
Filter (stop Hann band)... 0 34 0.1
Rename... cs2


#■Select SV Sample
selectObject: ari_sv_work_id
name$ = selected$ ("Sound")
namesv$ = left$(name$, 16)
Copy... sv



# --------------------------------------------------------------------------------------------
# PART 1:
# DETECTION, EXTRACTION AND CONCATENATION OF
# THE VOICED SEGMENTS IN THE RECORDING
# OF CONTINUOUS SPEECH.
# Detect, extract, and combine voiced parts of CS samples
# --------------------------------------------------------------------------------------------
select Sound cs2
Copy... original
samplingRate = Get sampling frequency
intermediateSamples = Get sampling period
durationCS = Get total duration
# Create 0.001 second file with Inteinsity0
Create Sound... onlyVoice 0 0.001 'samplingRate' 0 
select Sound original
#　Text grid feature to isolate the overall maximum Intnsity -25dB or less as silence
To TextGrid (silences)... 50 0.003 -25 0.1 0.1 silence sounding
select Sound original
plus TextGrid original
Extract intervals where... 1 no "does not contain" silence
Concatenate
select Sound chain
# Creating ONLY Loud samples
Rename... onlyLoud
numberOfonlyLoud =selected ("Sound") ;Syntax for the removement of intermediate objects
#　Set the sound pressure power of OnlyLoud as globalPower.
globalPower = Get power in air
select TextGrid original
call ariSafeRemove

# Remove intermediate objects
selectObject: numberOfonlyLoud-1
nameOflastsilence$ = selected$ ("Sound")
numberOfsilence = number(mid$ (nameOflastsilence$, 18, length(nameOflastsilence$)))
for j from 1 to numberOfsilence
selectObject: "Sound original_silence_'j'"
call ariSafeRemove
endfor
# Remove intermediate objects



# Generate “voiced” samples------------------------------------------------------
# First, the Onlyloud sample is divided into 30 ms segments.
# Next, segments that satisfy all the conditions of 30% or more of the sound pressure power of OnlyLoud and a zero-crossing rate of 3000 Hz or less are targeted.
# ------------------------------------------------------
select Sound onlyLoud
# Sample length of Onlyloud
signalEnd = Get end time
windowBorderLeft = Get start time
#0Split into .03s segments
#Argument at the end of segment
windowWidth = 0.03
windowBorderRight = windowBorderLeft + windowWidth
#　Set the sound pressure power of OnlyLoud as globalPower.
globalPower = Get power in air

voicelessThreshold = globalPower*(30/100)

select Sound onlyLoud
# Defines the rightmost side of the analysis
extremeRight = signalEnd - windowWidth
# Split from 0 seconds to 0,03 seconds each.
while windowBorderRight < extremeRight
	Extract part... 'windowBorderLeft' 'windowBorderRight' Rectangular 1.0 no
	select Sound onlyLoud_part
	partialPower = Get power in air
#　When the sound pressure power of OnlyLoud is set as globalPower, the first condition of “voiced sound” is defined as when the sound pressure power is divided by 0.03s and other areas have a sound pressure power of 30% or more of that value.
	if partialPower > voicelessThreshold
　　　　# Call procedure
		call checkZeros 0
	   # When zeroCrossingRate < 3000, 0.03 seconds are added as a voiced interval
　　　　if (zeroCrossingRate <> undefined) and (zeroCrossingRate < 3000)
			select Sound onlyVoice
			plus Sound onlyLoud_part
			Concatenate
			Rename... onlyVoiceNew
			select Sound onlyVoice
			call ariSafeRemove
			select Sound onlyVoiceNew
			Rename... onlyVoice
		endif
	endif
	select Sound onlyLoud_part
	call ariSafeRemove
	windowBorderLeft = windowBorderLeft + 0.03
	windowBorderRight = windowBorderLeft + 0.03
	select Sound onlyLoud
endwhile
select Sound onlyVoice
durationCSvoiced = Get total duration


# procedure named checkZeros 
#　zeroCrossingRate as an argument.





# --------------------------------------------------------------------------------------------
# PART 2:
# DETERMINATION OF THE 6 ACOUSTIC MEASURES
# AND CALCULATION OF THE ACOUSTIC Breathiness INDEX.
# --------------------------------------------------------------------------------------------

# Middle of sv 3 sec extraction
select Sound sv
durationVowel = Get total duration
durationStart=durationVowel/2-1.5
durationEnd=durationVowel/2+1.5
if durationVowel>3
Extract part... durationStart durationEnd rectangular 1 no
Rename... sv2
elsif durationVowel<=3
Copy... sv2
endif

# Concatenated in order of cs and sv (time not unified)
select Sound onlyVoice
durationOnlyVoice = Get total duration
plus Sound sv2
Concatenate
Rename... ari
durationAll = Get total duration
minimumSPL = Get minimum... 0 0 None
maximumSPL = Get maximum... 0 0 None


# Analyses

start = do ("Get start time")
end = do ("Get end time")
duration = do ("Get total duration")
durationAnalysisWindow = 0.1
halfDurationAnalysisWindow = durationAnalysisWindow/2
numberOfWindows = floor (duration/durationAnalysisWindow)

# Analyses on portions with durationAnalysisWindow


	# Intermediate tables

do ("Create Table with column names...", "hfno", 0, "hfno6000")
do ("Create Table with column names...", "hnrd", 0, "hnrd")
do ("Create Table with column names...", "h1h2", 0, "h1h2")


######### Segmentation into portions of 0.05 s, and analyses on these portions
######### Calculate each element by dividing by 0.1 second


for n from 1 to numberOfWindows

	selectObject ("Sound ari")
	endWindow = start + (n*durationAnalysisWindow)
	startWindow = endWindow-durationAnalysisWindow
	do ("Extract part...", startWindow, endWindow, "rectangular", 1, "yes")
	do ("Rename...", "soundInWindow")
	

# High Frequency Noise (hfno) ############################################################


	do ("To Spectrum...", "yes")
	do ("To Ltas (1-to-1)")

	ltasMinimum = do ("Get minimum...", 0, 10000, "None")
	if ltasMinimum < 0
       #If the minimum spectrum is less than 0 dB, add its absolute value and bottom out the minimum to 0
		ltasMinimum = abs (ltasMinimum)
		do ("Formula...", "self+ltasMinimum")
	elsif ltasMinimum >= 0
       #If the minimum spectrum is greater than 0 dB, subtract that amount to reduce the minimum to 0
		do ("Formula...", "self-ltasMinimum")
	endif
	#Calculate spectral power averages (0-6000 and 6000-10000)
　　#Find its ratio (0-6000 power/6000-10,000 power)
　　ltasEnergy0to6kHz = do ("Get mean...", 0, 6000, "energy")
	ltasEnergy6to10kHz = do ("Get mean...", 6000, 10000, "energy")
	hfno6000 = ltasEnergy0to6kHz/ltasEnergy6to10kHz
selectObject ("Table hfno")
　　# Add row row (horizontal) in all columns columm (vertical)
	do ("Append row")
　　#Fill in the number, element name, and number on that line
	do ("Set numeric value...", n, "hfno6000", hfno6000)　
　　#　Calculate the average of columm up to that point.
	meanhfno6000 = do ("Get mean...", "hfno6000")



	
# HNR-Dejonckere (hnrd) (between 0.5-1.5 kHz) ############################################################

　　　   # (after f0 determination: (a) cepstrum, (b) LTAS) 

	selectObject ("Sound soundInWindow")
	startSoundInWindow = do ("Get start time")
	middleSoundInWindow = startSoundInWindow+halfDurationAnalysisWindow
　　#Create a power spectrum for each frame
	do ("To PowerCepstrogram...", 61, 0.002, 5000, 50)
	do ("To PowerCepstrum (slice)...", middleSoundInWindow)
　　#Subtracting Calculation Noise
	do ("Subtract tilt...", 0.001, 0, "Straight", "Robust")
　　#Calculate CPP between 60-400 Hz
　	quefrencyPeak = do ("Get quefrency of peak...", 60, 400, "Parabolic")
	frequencySoundInWindow = 1/quefrencyPeak
　　#Search for f0 using spectral waveforms at 20 Hz before and after the peak frequency of CPP
　	frequencySoundInWindowLowerSearchLimit = frequencySoundInWindow-20
	frequencySoundInWindowUpperSearchLimit = frequencySoundInWindow+20
	selectObject ("Spectrum soundInWindow")
	do ("To Ltas...", 6)
	do ("Rename...", "soundInWindow2")
	peakInFrequencyZone = do ("Get frequency of maximum...", frequencySoundInWindowLowerSearchLimit, frequencySoundInWindowUpperSearchLimit, "None")
	#Calculate each overtone number that exists within 500-1500 Hz
　 　firstHarmonicIn500to1500 = ceiling (500/peakInFrequencyZone)
	lastHarmonicIn500to1500 = floor (1500/peakInFrequencyZone)
	do ("Create Table with column names...", "peaks", 0, "peakHeight")
	selectObject ("Ltas soundInWindow")
	for p from firstHarmonicIn500to1500 to lastHarmonicIn500to1500
		selectObject ("Ltas soundInWindow")
　　　　#Extract the peak Hz of harmonics at 500-1500 Hz and their spectral dB using the f0 frequency obtained above.
		harmonicZoneLeftBoundary = (p*peakInFrequencyZone)-20
		harmonicZoneRightBoundary = (p*peakInFrequencyZone)+20
		peakInHarmonicZone = do ("Get maximum...", harmonicZoneLeftBoundary, harmonicZoneRightBoundary, "None")
		selectObject ("Table peaks")
		do ("Append row")
		numberOfRows= do ("Get number of rows")
		do ("Set numeric value...", numberOfRows, "peakHeight", peakInHarmonicZone)
	endfor
	selectObject ("Table peaks")
    #Calculate peak dB average of overtone structure at 500-1500 Hz
　	meanPeakHeight = do ("Get mean...", "peakHeight")
	firstValleyIn500to1500 = firstHarmonicIn500to1500
	lastValleyIn500to1500 = (floor (1500/frequencySoundInWindow))-1
	do ("Create Table with column names...", "valleys", 0, "valleyDepth")
	selectObject ("Ltas soundInWindow")
	for v from firstValleyIn500to1500 to lastValleyIn500to1500
		selectObject ("Ltas soundInWindow")
　　　　  #between overtones existing between 500 and 1500 Hz (the lowest dB of the valley in the region narrowed by 20 Hz between the overtone peaks is calculated).		
        valleyZoneLeftBoundary = (v*peakInFrequencyZone)+20
		valleyZoneRightBoundary = ((v+1)*peakInFrequencyZone)-20
		depthInValleyZone = do ("Get minimum...", valleyZoneLeftBoundary, valleyZoneRightBoundary, "None")
		selectObject ("Table valleys")
		do ("Append row")
		numberOfRows= do ("Get number of rows")
		do ("Set numeric value...", numberOfRows, "valleyDepth", depthInValleyZone)
	endfor
	selectObject ("Table valleys")
	meanValleyDepth = do ("Get mean...", "valleyDepth")
　　#Difference between overtone Max average and noise mindB average at 500-1500Hz
	hnrd = meanPeakHeight-meanValleyDepth
	selectObject ("Table hnrd")
	do ("Append row")
	do ("Set numeric value...", n, "hnrd", hnrd)
	




# h1-h2############################################################

	firstHarmonicLowerBoundary = peakInFrequencyZone-20
	firstHarmonicUpperBoundary = peakInFrequencyZone+20
	h2PeakInFrequencyZone = peakInFrequencyZone*2
	secondHarmonicLowerBoundary = h2PeakInFrequencyZone-20
	secondHarmonicUpperBoundary = h2PeakInFrequencyZone+20
	selectObject ("Ltas soundInWindow2")
	h1Amplitude = do ("Get maximum...", firstHarmonicLowerBoundary, firstHarmonicUpperBoundary, "None")
	h2Amplitude = do ("Get maximum...", secondHarmonicLowerBoundary, secondHarmonicUpperBoundary, "None")
	h1h2 = h1Amplitude-h2Amplitude
	selectObject ("Table h1h2")
	do ("Append row")
	do ("Set numeric value...", n, "h1h2", h1h2)

endfor

#################　End of frame analysis


	# Retrieve final results from intermediate tables

selectObject ("Table hfno")
finalhfno6000 = do ("Get mean...", "hfno6000")

selectObject ("Table hnrd")
finalhnrd = do ("Get mean...", "hnrd")

selectObject ("Table h1h2")
finalH1H2 = do ("Get mean...", "h1h2")

#########################################################################
# ABI-original 60-Hz branch for HNR-Dejonckere and H1-H2
# -----------------------------------------------------------------------
# IMPORTANT:
# - ARI remains unchanged and continues to use the original ARI 61-Hz
#   PowerCepstrogram setting and finalhnrd.
# - ABI uses an independent 60-Hz branch matching the original ABI script.
# - For ABI HNR-Dejonckere, harmonic peaks/valleys are measured from the
#   normalized LTAS (1-to-1), while the f0 peak position is located on the
#   separate 6-Hz LTAS, exactly as in the original ABI implementation.
# - ABI H1-H2 is measured from the 6-Hz LTAS, as in the original ABI script.
#########################################################################

do ("Create Table with column names...", "hnrd_ABI60", 0, "hnrd_ABI60")
hnrd_ABI60_table_id = selected("Table")
do ("Create Table with column names...", "h1h2_ABI60", 0, "h1h2_ABI60")
h1h2_ABI60_table_id = selected("Table")

for n from 1 to numberOfWindows

    # Extract the same 0.1-s frame from the same concatenated Sound ari.
    selectObject ("Sound ari")
    endWindow_ABI60 = start + (n*durationAnalysisWindow)
    startWindow_ABI60 = endWindow_ABI60-durationAnalysisWindow
    do ("Extract part...", startWindow_ABI60, endWindow_ABI60, "rectangular", 1, "yes")
    abi60_frame_id = selected("Sound")

    # Create Spectrum and the normalized LTAS (1-to-1), as in original ABI.
    do ("To Spectrum...", "yes")
    abi60_spectrum_id = selected("Spectrum")
    do ("To Ltas (1-to-1)")
    abi60_ltas_1to1_id = selected("Ltas")
    ltasMinimum_ABI60 = do ("Get minimum...", 0, 10000, "None")
    if ltasMinimum_ABI60 < 0
        ltasMinimum_ABI60 = abs (ltasMinimum_ABI60)
        do ("Formula...", "self+ltasMinimum_ABI60")
    elsif ltasMinimum_ABI60 >= 0
        do ("Formula...", "self-ltasMinimum_ABI60")
    endif

    # ABI-original frame-wise f0 estimation: PowerCepstrogram floor = 60 Hz.
    selectObject: abi60_frame_id
    startSoundInWindow_ABI60 = do ("Get start time")
    middleSoundInWindow_ABI60 = startSoundInWindow_ABI60+halfDurationAnalysisWindow
    do ("To PowerCepstrogram...", 60, 0.002, 5000, 50)
    do ("To PowerCepstrum (slice)...", middleSoundInWindow_ABI60)
    do ("Subtract tilt...", 0.001, 0, "Straight", "Robust")
    quefrencyPeak_ABI60 = do ("Get quefrency of peak...", 60, 400, "Parabolic")
    frequencySoundInWindow_ABI60 = 1/quefrencyPeak_ABI60
    frequencySoundInWindowLowerSearchLimit_ABI60 = frequencySoundInWindow_ABI60-20
    frequencySoundInWindowUpperSearchLimit_ABI60 = frequencySoundInWindow_ABI60+20

    # Create the separate 6-Hz LTAS used to locate f0 and to measure H1-H2.
    selectObject: abi60_spectrum_id
    do ("To Ltas...", 6)
    abi60_ltas_6hz_id = selected("Ltas")
    peakInFrequencyZone_ABI60 = do ("Get frequency of maximum...", frequencySoundInWindowLowerSearchLimit_ABI60, frequencySoundInWindowUpperSearchLimit_ABI60, "None")

    # HNR-Dejonckere for ABI: peaks and valleys from normalized LTAS (1-to-1).
    firstHarmonicIn500to1500_ABI60 = ceiling (500/peakInFrequencyZone_ABI60)
    lastHarmonicIn500to1500_ABI60 = floor (1500/peakInFrequencyZone_ABI60)
    do ("Create Table with column names...", "peaks_ABI60", 0, "peakHeight")
    peaks_ABI60_table_id = selected("Table")
    for p from firstHarmonicIn500to1500_ABI60 to lastHarmonicIn500to1500_ABI60
        selectObject: abi60_ltas_1to1_id
        harmonicZoneLeftBoundary_ABI60 = (p*peakInFrequencyZone_ABI60)-20
        harmonicZoneRightBoundary_ABI60 = (p*peakInFrequencyZone_ABI60)+20
        peakInHarmonicZone_ABI60 = do ("Get maximum...", harmonicZoneLeftBoundary_ABI60, harmonicZoneRightBoundary_ABI60, "None")
        selectObject: peaks_ABI60_table_id
        do ("Append row")
        numberOfRows_ABI60 = do ("Get number of rows")
        do ("Set numeric value...", numberOfRows_ABI60, "peakHeight", peakInHarmonicZone_ABI60)
    endfor
    selectObject: peaks_ABI60_table_id
    meanPeakHeight_ABI60 = do ("Get mean...", "peakHeight")

    firstValleyIn500to1500_ABI60 = firstHarmonicIn500to1500_ABI60
    lastValleyIn500to1500_ABI60 = (floor (1500/frequencySoundInWindow_ABI60))-1
    do ("Create Table with column names...", "valleys_ABI60", 0, "valleyDepth")
    valleys_ABI60_table_id = selected("Table")
    for v from firstValleyIn500to1500_ABI60 to lastValleyIn500to1500_ABI60
        selectObject: abi60_ltas_1to1_id
        valleyZoneLeftBoundary_ABI60 = (v*peakInFrequencyZone_ABI60)+20
        valleyZoneRightBoundary_ABI60 = ((v+1)*peakInFrequencyZone_ABI60)-20
        depthInValleyZone_ABI60 = do ("Get minimum...", valleyZoneLeftBoundary_ABI60, valleyZoneRightBoundary_ABI60, "None")
        selectObject: valleys_ABI60_table_id
        do ("Append row")
        numberOfRows_ABI60 = do ("Get number of rows")
        do ("Set numeric value...", numberOfRows_ABI60, "valleyDepth", depthInValleyZone_ABI60)
    endfor
    selectObject: valleys_ABI60_table_id
    meanValleyDepth_ABI60 = do ("Get mean...", "valleyDepth")
    hnrd_ABI60 = meanPeakHeight_ABI60-meanValleyDepth_ABI60

    selectObject: hnrd_ABI60_table_id
    do ("Append row")
    do ("Set numeric value...", n, "hnrd_ABI60", hnrd_ABI60)

    # H1-H2 for ABI: measured from the 6-Hz LTAS.
    firstHarmonicLowerBoundary_ABI60 = peakInFrequencyZone_ABI60-20
    firstHarmonicUpperBoundary_ABI60 = peakInFrequencyZone_ABI60+20
    h2PeakInFrequencyZone_ABI60 = peakInFrequencyZone_ABI60*2
    secondHarmonicLowerBoundary_ABI60 = h2PeakInFrequencyZone_ABI60-20
    secondHarmonicUpperBoundary_ABI60 = h2PeakInFrequencyZone_ABI60+20
    selectObject: abi60_ltas_6hz_id
    h1Amplitude_ABI60 = do ("Get maximum...", firstHarmonicLowerBoundary_ABI60, firstHarmonicUpperBoundary_ABI60, "None")
    h2Amplitude_ABI60 = do ("Get maximum...", secondHarmonicLowerBoundary_ABI60, secondHarmonicUpperBoundary_ABI60, "None")
    h1h2_ABI60 = h1Amplitude_ABI60-h2Amplitude_ABI60

    selectObject: h1h2_ABI60_table_id
    do ("Append row")
    do ("Set numeric value...", n, "h1h2_ABI60", h1h2_ABI60)

endfor

selectObject: hnrd_ABI60_table_id
finalhnrd_ABI60 = do ("Get mean...", "hnrd_ABI60")

selectObject: h1h2_ABI60_table_id
finalH1H2_ABI60 = do ("Get mean...", "h1h2_ABI60")

# Analyses on whole sound




#########################################################################
		# Slope of the long-term average spectrum　　【slope】
#########################################################################
selectObject ("Sound ari")
To Ltas... 1
slope = Get slope... 0 1000 1000 10000 energy

#########################################################################
　　　# Tilt of trendline through the long-term average spectrum　【tilt】
#########################################################################
Compute trend line... 1 10000
tilt = Get slope... 0 1000 1000 10000 energy


#########################################################################
　　　# Harmonic-to-noise ratio　【hnr】
#########################################################################
selectObject ("Sound ari")
To Pitch (cc)... 0 75 15 no 0.03 0.45 0.01 0.35 0.14 600
selectObject ("Sound ari")
plusObject ("Pitch ari")
To PointProcess (cc)
selectObject ("Sound ari")
plusObject ("Pitch ari")
plusObject ("PointProcess ari_ari")
voiceReport$ = Voice report... 0 0 75 600 1.3 1.6 0.03 0.45
hnr = extractNumber (voiceReport$, "Mean harmonics-to-noise ratio: ")

# Praat's smoothed cepstral peak prominence (cpps) ############################################################
　　
　　#Calculate CPP between 60-400 Hz
　　#▲▲However, if there are strong subharmonics within this range, errors occur in which that frequency band is detected as CPP ▲▲
　　#▲▲Also, when the overtones are extremely attenuated, as in the case of strong breathiness, the CPP itself is all low, and the error is large, so the CPP does not necessarily correspond to the first overtone.▲▲　	

selectObject ("Sound ari")
do ("To PowerCepstrogram...", 60, 0.002, 5000, 50)
cpps = do ("Get CPPS...", "no", 0.01, 0.001, 60, 330, 0.05, "Parabolic", 0.001, 0, "Straight", "Robust")


# Praat's jitter ############################################################
		
selectObject ("Sound ari")
do ("To Pitch...", 0, 70, 600)
selectObject ("Sound ari")
plusObject ("Pitch ari")
do ("To PointProcess (cc)")
selectObject ("Sound ari")
plusObject ("Pitch ari")
plusObject ("PointProcess ari_ari")
voiceReport$ = Voice report... 0 0 70 600 1.3 1.6 0.03 0.45
jitterLocalPre = extractNumber (voiceReport$, "Jitter (local): ")
jitterLocal = jitterLocalPre*100

# Praat's shimmers ############################################################

shimmerLocalPre = extractNumber (voiceReport$, "Shimmer (local): ")
shimmerLocal = shimmerLocalPre*100
shimmerLocaldB = extractNumber (voiceReport$, "Shimmer (local, dB): ")

# Natural logarithm of Praat's standard deviation of period (psd) (lnpsd)############################################################

psd = extractNumber (voiceReport$, "Standard deviation of period: ")

# Glottal-to-Noise Excitation ratio (gne)############################################################

selectObject ("Sound ari")
do ("To Harmonicity (gne)...", 500, 4500, 1000, 80)
gneMaximum = do ("Get maximum")


# Remove analysis-created intermediate objects while preserving everything
# that existed before the analysis procedure was invoked.
select all
call ariSafeRemove
label without_others

#################################################################
######################## Exporting calculation results　#########################
#################################################################


if draw_Figure = 1
do ("Select outer viewport...", 0, 10, 8, 12)
endif
#################################################################
######################## Calculate ARI (and ABI)　###############################
#################################################################

ari = 4.869405796723514 - 0.068586*chaoticNoise_Power_of_all + 0.107947*superSubharmonics_of_all + 0.000516*one_3rdSubharmonics_of_all + 0.017007*one_halfSubharmonics_of_all - 0.226746*finalhfno6000 - 0.023793*finalhnrd + 0.035208*cpps + 2.019074*shimmerLocaldB + 545.539678*psd - 1.054173*gneMaximum + 0.003609*slope + 0.052504*tilt
# ABI uses the original ABI 60-Hz HNR-D/H1-H2 branch.
abi =(5.0447730915-(0.172*cpps)-(0.193*jitterLocal)-(1.283*gneMaximum)-(0.396*finalhfno6000)+(0.01*finalhnrd_ABI60)+(0.017*finalH1H2_ABI60)+(1.473*shimmerLocaldB)-(0.088*shimmerLocal)-(68.295*psd))*2.9257400394


#appendInfoLine: ari
about$ = fixed$(ari, 2)

resultline$ = sample_id$ + tab$ + cs_file_name$ + tab$ + sv_file_name$
resultline$ = resultline$ + tab$ + string$(ari) + tab$ + string$(abi) + tab$ + string$(chaoticNoise_Power_of_all)
resultline$ = resultline$ + tab$ + string$(superSubharmonics_Power_of_all) + tab$ + string$(one_3rdSubharmonics_Power_of_all) 
resultline$ = resultline$ + tab$ + string$(one_halfSubharmonics_Power_of_all) + tab$ + string$(superSubharmonics_of_all)
resultline$ = resultline$ + tab$ + string$(one_3rdSubharmonics_of_all) + tab$ + string$(one_halfSubharmonics_of_all) 
resultline$ = resultline$ + tab$ + string$(finalhfno6000) + tab$ + string$(finalhnrd) + tab$ + string$(finalH1H2) + tab$ + string$(finalhnrd_ABI60) + tab$ + string$(finalH1H2_ABI60) + tab$ + string$(cpps) 
resultline$ = resultline$ + tab$ + string$(jitterLocal) + tab$ + string$(shimmerLocal) + tab$ + string$(shimmerLocaldB) + tab$ + string$(psd) 
resultline$ = resultline$ + tab$ + string$(gneMaximum) + tab$ + string$(slope) + tab$ + string$(tilt) + tab$ + string$(hnr) + tab$ + string$(praatVersion)
appendFileLine: result_file$, resultline$
appendFileLine: analysis_log_file$, run_mode$, tab$, string$(pair_index), tab$, string$(total_pairs), tab$, sample_id$, tab$, cs_file_name$, tab$, sv_file_name$, tab$, "OK", tab$, string$(ari), tab$, string$(abi), tab$, praatVersion
writeFileLine: marker_file$, "ARI=" + string$(ari) + tab$ + "ABI=" + string$(abi)
writeFileLine: stage_file$, "Finished"

#################################################################
############## Start drawing calculation results to Innner Viewport　#################
#################################################################
if draw_Figure = 1
# Data display part
    Font size... 10.5
    Select inner viewport... 0.5 4.1 9.2 11.6
    Draw inner box
    Axes... 0 12 12 0
    Text... 0.05 Left 0.5 Half 1/2 Subharmonics: ##'one_halfSubharmonics_of_all:3' \% #
    Text... 0.05 Left 1.5 Half 1/3 Subharmonics: ##'one_3rdSubharmonics_of_all:3' \% #
    Text... 0.05 Left 2.5 Half Super Subharmonics: ##'superSubharmonics_of_all:3' \% #
    Text... 0.05 Left 3.5 Half Chaotic noise energy (relative to fo): ##-1 * 'chaoticNoise_Power_of_all:3' dB#
    Text... 0.05 Left 4.5 Half Smoothed cepstral peak prominence (CPPS): ##'cpps:3' dB#
    Text... 0.05 Left 5.5 Half Glottal-to-Noise Excitation ratio (4.5 kHz freq-max): ##'gneMaximum:3'#
    Text... 0.05 Left 6.5 Half High Frequency Noise of 6000 Hz: ##'finalhfno6000:3' dB#
    Text... 0.05 Left 7.5 Half Harmonics-to-Noise Ratio of Dejonckere: ##'finalhnrd:3' dB#
    Text... 0.05 Left 8.5 Half Shimmer local dB: ##'shimmerLocaldB:3' dB#
    Text... 0.05 Left 9.5 Half Period standard deviation: ##'psd:5' sec#
    Text... 0.05 Left 10.5 Half Slope of the LTAS: ##'slope:3' #
    Text... 0.05 Left 11.5 Half Tilt of trendline through the LTAS: ##'tilt:3' #
    Font size... 9
    Text... 11.5 Right 11.5 Half Praat 'praatVersion'



#Drawing part of ARI
    Select inner viewport...  4.5 9.5 10.3 11.0
    Draw inner box
    Axes... 0 10 1 0
    Marks top every... 1 1 yes yes no
    Draw inner box
    Paint rectangle... cyan 0 2.087753 0 1 
    Paint rectangle... red 2.087753 10 0 1 
#Draw arrows based on ARI scores
if ari<> undefined
    Select inner viewport... 4.5 9.5 10.3 11.0
    Arrow size... 2
　　Draw arrow... ari 1 ari 0  
endif
#Add ARI calculation results
    Font size... 25
    Select inner viewport... 4.5 9.5 9.5 10.0
    Axes... 0 10 1 0
    Text... 5 Centre 0.5 Half ARI: ##'about$'#

goto skipABI
#Drawing part of ARI
    Select inner viewport... 4.5 9.5 9.6 10.3
    Draw inner box
    Axes... 0 10 1 0
    Marks top every... 1 1 yes yes no
    Draw inner box
    Paint rectangle... cyan 0 2.087753 0 1 
    Paint rectangle... red 2.087753 10 0 1 

#Draw arrows based on ARI scores
if ari<> undefined
    Select inner viewport... 4.5 9.5 9.6 10.3
    Arrow size... 2
　　Draw arrow... ari 1 ari 0  
endif
#Add ARI calculation results
    Font size... 16
    Select inner viewport... 4.5 9.5 9 9.5
    Axes... 0 10 1 0
    Text... 5 Centre 0.5 Half ARIv1: ##'about$'#

#Drawing part of ABI
    Font size... 9
    Select inner viewport... 4.5 9.5 10.9 11.6
    Draw inner box
    Axes... 0 10 1 0
    Marks top every... 1 1 yes yes no
    Draw inner box
    Paint rectangle... cyan 0 3.44 0 1 
    Paint rectangle... red 3.44 10 0 1 
#Draw arrows based on ABI scores ●Add abi calculation results
if abi<> undefined
    Select inner viewport... 4.5 9.5 10.9 11.6
    Arrow size... 2
　　Draw arrow... abi 1 abi 0  
endif
#Add ABI calculation results
    Font size... 16
    Select inner viewport... 4.5 9.5 10.3 10.8
    Axes... 0 10 1 0
    Text... 5 Centre 0.5 Half ABI: ##'abi:2'#
label skipABI
endif

endif

#################################################################
############## Finish drawing calculation results to Innner Viewport　#################
#################################################################



if save_Figure = 1
    do ("Select outer viewport...", 0, 10, 0, 12)
    figure_file$ = save_directory$ + "/Result_" + namecs$ + ".png"
    do ("Save as 300-dpi PNG file...", figure_file$)
# else
#     do ("Select outer viewport...", 0, 10, 0, 8)
#     do ("Save as 300-dpi PNG file...", "'save_directory$'\Result'namecs$'.png")
endif




#################################################

########################################################################
# Safe object cleanup
# Removes only currently selected objects that did NOT exist before this
# ARI run. Pre-existing objects are never removed.
########################################################################
endproc

procedure checkZeros zeroCrossingRate
	start = 0.0025
	startZero = Get nearest zero crossing... 'start'
	findStart = startZero
	findStartZeroPlusOne = startZero + intermediateSamples
	startZeroPlusOne = Get nearest zero crossing... 'findStartZeroPlusOne'
	zeroCrossings = 0
	strips = 0

	while (findStart < 0.0275) and (findStart <> undefined)
		while startZeroPlusOne = findStart
			findStartZeroPlusOne = findStartZeroPlusOne + intermediateSamples
			startZeroPlusOne = Get nearest zero crossing... 'findStartZeroPlusOne'
		endwhile
		afstand = startZeroPlusOne - startZero
		strips = strips +1
		zeroCrossings = zeroCrossings +1
		findStart = startZeroPlusOne
	endwhile
	zeroCrossingRate = zeroCrossings/afstand
endproc

procedure ariSafeRemove
    .selected_ids# = selected# ()
    for .i to size (.selected_ids#)
        .remove_id = .selected_ids# [.i]
        .is_preexisting = 0
        for .j to size (ari_preexisting_ids#)
            if .remove_id = ari_preexisting_ids# [.j]
                .is_preexisting = 1
            endif
        endfor
        if .is_preexisting = 0
            selectObject: .remove_id
            Remove
        endif
    endfor
endproc

#!/bin/bash

root_dir="/project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_A4"
FA_dir="/project/4180000.24/analysis_wessel/DTI/LPI_253_DS_A4/FA_results"
MD_dir="/project/4180000.24/analysis_wessel/DTI/LPI_253_DS_A4/MD_results"
anat_dir="/project/4180000.24/analysis_wessel/DTI/LPI_253_DS_A4/anat_reg"
dwi_dir="/project/4180000.24/analysis_wessel/DTI/LPI_253_DS_A4/dwi_reg"
#b0_dir="/project/4180000.24/analysis_wessel/DTI/LPI_253_DS_manualDWI/b0"

mkdir -p $FA_dir
mkdir -p $MD_dir
mkdir -p $anat_dir
mkdir -p $dwi_dir
#mkdir -p $b0_dir

for folder in ${root_dir}/sub-* ; do
    FA=$(find ${folder}/"dwi" -type f -name "*FA_reg.nii.gz")
    MD=$(find ${folder}/"dwi" -type f -name "*MD_reg.nii.gz")
    anat=$(find ${folder}/"anat" -type f -name "anat2template.png")
    dwi=$(find ${folder}/"dwi" -type f -name "dwi2template.png")
#    b0=$(find ${folder}/"tmp_data/dwi" -type f -name "b0_tmean.nii.gz")

   anat_base=$(basename ${anat})
   dwi_base=$(basename ${dwi})
#   b0_base=$(basename ${b0})
   anat_noext="${anat_base%.*}"
   dwi_noext="${dwi_base%.*}"
#   b0_noext="${b0_base%.*}"
   subject_base=$(basename ${folder})
   subject=${subject_base#"sub-"}

   cp -r "${FA}" "${FA_dir}"
   cp -r "${MD}" "${MD_dir}"
   cp -r "$anat" "$anat_dir/${anat_noext}_${subject}.png"
   cp -r "${dwi}" "${dwi_dir}/${dwi_noext}_${subject}.png"
 #  cp -r "${b0}" "${b0_dir}/${b0_noext}_${subject}.nii.gz"
done

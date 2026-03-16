#!/bin/bash

#Author: Wessel van Engelenburg
#Date: 11/04/24
#Last modified on: ... (by: ... )

cd /project/4180000.24/analysis_wessel/DTI/analysis/
root_dir="/project/4180000.24/analysis_wessel/DTI/analysis/"
template="/project/4180000.24/analysis_wessel/DTI/template/DSURQE_100micron_average_LPI.nii.gz"
template_mask="/project/4180000.24/analysis_wessel/DTI/template/DSURQE_100micron_mask_dilated_LPI.nii.gz"


mkdir -p $root_dir/tmp_script

for subject_folder in $root_dir/sub-*/; do

    subject_basename=$(basename -- ${subject_folder})
    
    
    echo "module load afni
    module load ants
    module unload fsl
    module load fsl/6.0.5
" > ${root_dir}/tmp_script/script_${subject_basename}.sh

    echo "
    cd ${subject_folder}
    anat_file=\$(find ${subject_folder}/anat -type f -name \"*T2w.nii.gz\")
    anat2temp='anat2temp.nii.gz'
    anat2temp_inv='anat2temp_inv.nii.gz'
    anat_base=\$(basename \${anat_file})
    anat_noext=\"\$(remove_ext \${anat_base})\"
    echo "Anatomical file: \${anat_file}"
    echo "Template mask: ${template_mask}"
    echo "Anatomical base: \${anat_base}"
    echo "Anatomical noext: \${anat_noext}"
    echo "Anatomical anat2temp: \${anat2temp}"
    echo "Anatomical inverse_anat2temp: \${anat2temp_inv}"


" >> ${root_dir}/tmp_script/script_${subject_basename}.sh

    echo "
mkdir -p "${subject_folder}/tmp_data/anat"
cp "${subject_folder}/anat/"* "${subject_folder}/tmp_data/anat" || { echo "Failed to copy files"; exit 1; }
" >> ${root_dir}/tmp_script/script_${subject_basename}.sh

    echo "cd ${subject_folder}/tmp_data/anat
" >> ${root_dir}/tmp_script/script_${subject_basename}.sh

    echo "
    3drefit -deoblique -overwrite \${anat_base}
    3dAutobox -prefix \${anat_noext}'_auto.nii.gz' -input \${anat_base}
    N4BiasFieldCorrection -d 3 -i \${anat_noext}'_auto.nii.gz' -o \${anat_noext}'_N4.nii.gz' 
    DenoiseImage -d 3 -i \${anat_noext}'_N4.nii.gz'  -o \${anat_noext}'_N4_dn.nii.gz'
    ImageMath 3 \${anat_noext}'_N4_dn.nii.gz' TruncateImageIntensity \${anat_noext}'_N4_dn.nii.gz' 0.05 0.999

    fslmaths \$(find ${subject_folder}/anat -type f -name \"*mask.nii.gz\") -kernel 3D -dilM ${subject_folder}/anat/\${anat_noext}'_mask_dilated.nii.gz'
    anat_mask=\$(find ${subject_folder}/anat -type f -name \"*dilated.nii.gz\")
    echo "Anatomical mask: \${anat_mask}"
" >> ${root_dir}/tmp_script/script_${subject_basename}.sh


    echo "mkdir -p reg
    antsRegistration --dimensionality 3 --float 0 -a 0 -v 1 --output reg/anat2std --interpolation Linear --winsorize-image-intensities [0.005,0.995] --use-histogram-matching 0 --initial-moving-transform [${template},\${anat_noext}'_N4_dn.nii.gz',1] --transform Rigid[0.1] --metric MI[${template},\${anat_noext}'_N4_dn.nii.gz',1,32] --convergence [500x250x100,1e-6,10] --shrink-factors 4x2x1 --smoothing-sigmas 2x1x0vox --transform Affine[0.1] --metric MI[${template},\${anat_noext}'_N4_dn.nii.gz',1,32] --convergence [500x250x100,1e-6,10] --shrink-factors 4x2x1 --smoothing-sigmas 2x1x0vox --transform SyN[0.1,3,0] --metric CC[${template},\${anat_noext}'_N4_dn.nii.gz',1,2] --convergence [30x20x5,1e-6,10] --shrink-factors 4x2x1 --smoothing-sigmas 2x1x0vox  --masks [${template_mask},\${anat_mask}]


    ComposeMultiTransform 3 \${anat2temp} -R ${template} reg/anat2std1Warp.nii.gz reg/anat2std0GenericAffine.mat

    ComposeMultiTransform 3 \${anat2temp_inv} -R ${template} -i reg/anat2std0GenericAffine.mat reg/anat2std1InverseWarp.nii.gz  

    antsApplyTransforms -i \${anat_noext}'_N4_dn.nii.gz' -r ${template} -t \${anat2temp} -o \${anat_noext}'_2std.nii.gz'
" >> ${root_dir}/tmp_script/script_${subject_basename}.sh


    echo "slicer \${anat_noext}'_2std.nii.gz' ${template} -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard1.png ; slicer ${template} \${anat_noext}'_2std.nii.gz' -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard2.png ; pngappend highres2standard1.png - highres2standard2.png anat2template.png; rm -f sl?.png highres2standard2.png

    rm highres2standard1.png
" >> ${root_dir}/tmp_script/script_${subject_basename}.sh

    echo "cp \${anat_noext}'_N4_dn.nii.gz' reg/

    #copy stuff out of tmp dir
    cp \${anat_noext}'_N4_dn.nii.gz' ${subject_folder}/anat/
    cp \${anat_noext}'_2std.nii.gz' ${subject_folder}/anat/
    cp \${anat_noext}'_N4.nii.gz' ${subject_folder}/anat/
    cp anat2template.png ${subject_folder}/anat/
" >> ${root_dir}/tmp_script/script_${subject_basename}.sh

    echo "#from here DWI registration starts -------------------------------------------------------------------

    dwi_file=${subject_folder}/dwi/*dwi.nii.gz
    dwi=\$(basename \${dwi_file%})
    dwi_noext=\"\$(remove_ext \${dwi})\"
    subses=\$(basename \"\${dwi%_ses-1_dwi.nii.gz}\")
    echo "DWI file: \${dwi_file}"
    echo "DWI base: \${dwi}"
    echo "DWI_noext: \${dwi_noext}"
    echo "DWI subses: \${subses}"

    mkdir -p ${subject_folder}/tmp_data/dwi
    cp reg/* ${subject_folder}/tmp_data/dwi
    cd ${subject_folder}/dwi
    cp -r * . ${subject_folder}/tmp_data/dwi
" >> ${root_dir}/tmp_script/script_${subject_basename}.sh



    echo " #first 5 volumes are b0
    b0=4

    cd ${subject_folder}/tmp_data/dwi
" >> ${root_dir}/tmp_script/script_${subject_basename}.sh

    echo "#correct for eddy currents & motion...get B0 map... retrieve temporal mean of B0
    eddy_correct \${dwi_file} \${dwi_noext}'_eddy.nii' 0
    3dvolreg -prefix \${dwi_noext}'_mc.nii.gz' \${dwi_noext}'_eddy.nii'
    3dresample -inset \${dwi_noext}'_mc.nii.gz'[0..\$b0] -prefix b0.nii.gz 
    fslmaths b0.nii.gz -Tmean b0_tmean.nii.gz

" >> ${root_dir}/tmp_script/script_${subject_basename}.sh

    echo "#define the preprocessed anatomical that has been registered onto template
    anat_reg=$subject_folder/anat/\${anat_noext}'_2std.nii.gz'

    #define preprocessed anatomical that hasnt been registered yet
    cp -r \${anat_reg} ./
    anat=\${anat_noext}'_N4_dn.nii.gz'
" >> ${root_dir}/tmp_script/script_${subject_basename}.sh

    echo "
    mkdir -p reg/
    antsRegistration --dimensionality 3 --float 0 -a 0 -v 1 --output reg/dwi2anat --interpolation Linear --winsorize-image-intensities [0.005,0.995] --use-histogram-matching 0 --initial-moving-transform [\${anat},'b0_tmean.nii.gz',1] --transform Rigid[0.1] --metric MI[\${anat},'b0_tmean.nii.gz',1,32] --convergence [50,1e-6,10] --shrink-factors 1 --smoothing-sigmas 0vox --masks [\${anat_mask}, none]

    cp anat2std* reg/

    dwi2temp=\${subses}'_b0_reg.nii.gz'
    dwi2anat=\${subses}'_b02anat.nii.gz' 

    antsApplyTransforms -d 3 -e 4 -i b0_tmean.nii.gz -r \$anat -t reg/dwi2anat0GenericAffine.mat -o \${dwi2anat}
    antsApplyTransforms -d 3 -e 4 -i b0_tmean.nii.gz -r \$template -t reg/anat2std1Warp.nii.gz -t reg/anat2std0GenericAffine.mat -t reg/dwi2anat0GenericAffine.mat -o \${dwi2temp}
" >> ${root_dir}/tmp_script/script_${subject_basename}.sh



    echo "slicer \${dwi2anat} \${anat} -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard1.png ; slicer \${anat} \${dwi2anat} -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard2.png ; pngappend highres2standard1.png - highres2standard2.png dwi2anat_lin.png; rm -f sl?.png highres2standard2.png
rm highres2standard1.png

    slicer \${dwi2temp} ${template} -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard1.png ; slicer ${template} \${dwi2temp} -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard2.png ; pngappend highres2standard1.png - highres2standard2.png dwi2template.png; rm -f sl?.png highres2standard2.png
rm highres2standard1.png
" >> ${root_dir}/tmp_script/script_${subject_basename}.sh


    echo "#compute dtifit
    #Register anatotmical map onto b0 map
    antsApplyTransforms -d 3 -i \${anat_mask} -r b0_tmean.nii.gz -t [reg/dwi2anat0GenericAffine.mat,1] -o brain_mask.nii.gz

    dtifit -k \${dwi_noext}'_eddy.nii' -o dtifit -m brain_mask.nii.gz -r \${dwi_noext}'.bvec' -b \${dwi_noext}'.bval'

    antsApplyTransforms -d 3 -i dtifit_FA.nii.gz -r ${template} -t reg/anat2std1Warp.nii.gz -t reg/anat2std0GenericAffine.mat -t reg/dwi2anat0GenericAffine.mat -o \${subses}'_dtifit_FA_reg.nii.gz'
    antsApplyTransforms -d 3 -i dtifit_MD.nii.gz -r ${template} -t reg/anat2std1Warp.nii.gz -t reg/anat2std0GenericAffine.mat -t reg/dwi2anat0GenericAffine.mat -o \${subses}'_dtifit_MD_reg.nii.gz'
" >> ${root_dir}/tmp_script/script_${subject_basename}.sh

    echo "
#copy files from DTI analysis to dwi folder
cp dwi2template.png ${subject_folder}/dwi
    cp \${subses}'_dtifit_FA_reg.nii.gz' ${subject_folder}/dwi
    cp \${subses}'_dtifit_MD_reg.nii.gz' ${subject_folder}/dwi

    #remove temp_data folder
    cd ${subject_folder}/
    rm -r tmp_data/

" >> ${root_dir}/tmp_script/script_${subject_basename}.sh

done

#for file in $root_dir/tmp_script/*
#do
#    qsub -l "walltime=4:00:00,mem=16gb,procs=2" $file
#done






#load necesarry programs
module load afni
    module load ants
    module unload fsl
    module load fsl/6.0.7.13

#set working directory to subject folder
    cd /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002/

#define variables necessary for anatomical to template reg
    anat_file=$(find /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//anat -type f -name "*T2w.nii.gz")
    anat2temp='anat2temp.nii.gz'
    anat2temp_inv='anat2temp_inv.nii.gz'
    anat_base=$(basename ${anat_file})
    anat_noext="$(remove_ext ${anat_base})"
    echo Anatomical file: ${anat_file}
    echo Template mask: /project/4180000.24/analysis_wessel/DTI/template/DSURQE_100micron_mask_dilated_LPI.nii.gz
    echo Anatomical base: ${anat_base}
    echo Anatomical noext: ${anat_noext}
    echo Anatomical anat2temp: ${anat2temp}
    echo Anatomical inverse_anat2temp: ${anat2temp_inv}



#create temporary data folder for anat reg, move necessary files to it and change WD to that folder
mkdir -p /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//tmp_data/anat
cp /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//anat/* /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//tmp_data/anat || { echo Failed to copy files; exit 1; }
cd /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//tmp_data/anat

#preprocess anatomical data
    3drefit -deoblique -overwrite ${anat_base}
    3dAutobox -prefix ${anat_noext}'_auto.nii.gz' -input ${anat_base}
    N4BiasFieldCorrection -d 3 -i ${anat_noext}'_auto.nii.gz' -o ${anat_noext}'_N4.nii.gz' 
    DenoiseImage -d 3 -i ${anat_noext}'_N4.nii.gz'  -o ${anat_noext}'_N4_dn.nii.gz'
    ImageMath 3 ${anat_noext}'_N4_dn.nii.gz' TruncateImageIntensity ${anat_noext}'_N4_dn.nii.gz' 0.05 0.999

#dilute the anatomical mask
    fslmaths $(find /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//anat -type f -name "*mask.nii.gz") -kernel 3D -dilM /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//anat/${anat_noext}'_mask_dilated.nii.gz'
    anat_mask=$(find /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//anat -type f -name "*dilated.nii.gz")
    echo Anatomical mask: ${anat_mask}

#create folder for output or registration call. Below: Anatomical to template registration call
mkdir -p reg
    antsRegistration --dimensionality 3 --float 0 -a 0 -v 1 --output reg/anat2std --interpolation Linear --winsorize-image-intensities [0.005,0.995] --use-histogram-matching 0 --initial-moving-transform [/project/4180000.24/analysis_wessel/DTI/template/DSURQE_100micron_average_LPI.nii.gz,${anat_noext}'_N4_dn.nii.gz',1] --transform Rigid[0.1] --metric MI[/project/4180000.24/analysis_wessel/DTI/template/DSURQE_100micron_average_LPI.nii.gz,${anat_noext}'_N4_dn.nii.gz',1,32] --convergence [500x250x100,1e-6,10] --shrink-factors 4x2x1 --smoothing-sigmas 2x1x0vox --transform Affine[0.1] --metric MI[/project/4180000.24/analysis_wessel/DTI/template/DSURQE_100micron_average_LPI.nii.gz,${anat_noext}'_N4_dn.nii.gz',1,32] --convergence [500x250x100,1e-6,10] --shrink-factors 4x2x1 --smoothing-sigmas 2x1x0vox --transform SyN[0.1,3,0] --metric CC[/project/4180000.24/analysis_wessel/DTI/template/DSURQE_100micron_average_LPI.nii.gz,${anat_noext}'_N4_dn.nii.gz',1,2] --convergence [30x20x5,1e-6,10] --shrink-factors 4x2x1 --smoothing-sigmas 2x1x0vox  --masks [/project/4180000.24/analysis_wessel/DTI/template/DSURQE_100micron_mask_dilated_LPI.nii.gz,${anat_mask}]


#combine generic transform matrix (rigid&affine) with non linear gradient field
    ComposeMultiTransform 3 ${anat2temp} -R /project/4180000.24/analysis_wessel/DTI/template/DSURQE_100micron_average_LPI.nii.gz reg/anat2std1Warp.nii.gz reg/anat2std0GenericAffine.mat

#also inverse (not used)
    ComposeMultiTransform 3 ${anat2temp_inv} -R /project/4180000.24/analysis_wessel/DTI/template/DSURQE_100micron_average_LPI.nii.gz -i reg/anat2std0GenericAffine.mat reg/anat2std1InverseWarp.nii.gz  

#apply the transform on the preprocessed anatomical image
    antsApplyTransforms -i ${anat_noext}'_N4_dn.nii.gz' -r /project/4180000.24/analysis_wessel/DTI/template/DSURQE_100micron_average_LPI.nii.gz -t ${anat2temp} -o ${anat_noext}'_2std.nii.gz'

#slicer function to generate .png to check overlap of transformed anat with template
slicer ${anat_noext}'_2std.nii.gz' /project/4180000.24/analysis_wessel/DTI/template/DSURQE_100micron_average_LPI.nii.gz -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard1.png ; slicer /project/4180000.24/analysis_wessel/DTI/template/DSURQE_100micron_average_LPI.nii.gz ${anat_noext}'_2std.nii.gz' -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard2.png ; pngappend highres2standard1.png - highres2standard2.png anat2template.png; rm -f sl?.png highres2standard2.png

    rm highres2standard1.png

cp ${anat_noext}'_N4_dn.nii.gz' reg/

    #copy stuff out of tmp dir
    cp ${anat_noext}'_N4_dn.nii.gz' /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//anat/
    cp ${anat_noext}'_2std.nii.gz' /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//anat/
    cp ${anat_noext}'_N4.nii.gz' /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//anat/
    cp anat2template.png /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//anat/

#from here DWI registration starts -------------------------------------------------------------------

#define varibales necessary for DWI registration

    dwi_file=/project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//dwi/*dwi.nii.gz
    dwi=$(basename ${dwi_file%})
    dwi_noext="$(remove_ext ${dwi})"
    subses=$(basename "${dwi%_ses-1_dwi.nii.gz}")
    echo DWI file: ${dwi_file}
    echo DWI base: ${dwi}
    echo DWI_noext: ${dwi_noext}
    echo DWI subses: ${subses}

#make temp dir for dwi reg, copy necessary files into it
    mkdir -p /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//tmp_data/dwi
    cp reg/* /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//tmp_data/dwi
    cd /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//dwi
    cp -r * . /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//tmp_data/dwi

#first 5 volumes are b0
    b0=4

#Move WD to temp dwi reg folder
cd /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//tmp_data/dwi

#correct for eddy currents & motion...get B0 map... retrieve temporal mean of B0
    eddy_correct ${dwi_file} ${dwi_noext}'_eddy.nii' 0
    3dvolreg -prefix ${dwi_noext}'_mc.nii.gz' ${dwi_noext}'_eddy.nii'
    3dresample -inset ${dwi_noext}'_mc.nii.gz'[0..$b0] -prefix b0.nii.gz 
    fslmaths b0.nii.gz -Tmean b0_tmean.nii.gz
    N4BiasFieldCorrection -d 3 -i b0_tmean.nii.gz -o b0_n4.nii.gz


#define the preprocessed anatomical that has been registered onto template
    anat_reg=/project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//anat/${anat_noext}'_2std.nii.gz'

#define preprocessed anatomical that hasnt been registered yet
    cp -r ${anat_reg} ./
    anat=${anat_noext}'_N4_dn.nii.gz'


    dwi2anat_ri=${subses}'_b02anat_ri.nii.gz' 
    dwi2anat_syn=${subses}'_b02anat_syn.nii.gz'
    dwi2temp=${subses}'_b0_reg.nii.gz'

#make DWI reg output folder 
    mkdir -p reg/
    cp anat2std* reg/

#First step DWI reg: anat-->DWI Rigid 
    antsRegistration --dimensionality 3 --float 0 -a 0 -v 1 --output reg/anat2dwi_ri --interpolation Linear --winsorize-image-intensities [0.005,0.995] --use-histogram-matching 0 --initial-moving-transform ['b0_n4.nii.gz',${anat},1] --transform Rigid[0.1] --metric MI['b0_n4.nii.gz',${anat},32] --convergence [50,1e-6,10] --shrink-factors 1 --smoothing-sigmas 0vox --masks [none,${anat_mask}]

#apply inverse transform to get DWI-->anat
    antsApplyTransforms -d 3 -e 4 -i b0_n4.nii.gz -r $anat -t [reg/anat2dwi_ri0GenericAffine.mat,1] -o ${dwi2anat_ri}

#Register anatomical map onto b0 map
    antsApplyTransforms -d 3 -i ${anat_mask} -r b0_tmean.nii.gz -t reg/anat2dwi_ri0GenericAffine.mat -o brain_mask.nii.gz

#use registered anat mask as b0 map in second step DWI reg: anat-->DWI2anat_rigid
    antsRegistration --dimensionality 3 --float 0 -a 0 -v 1 --output reg/anat2dwi_syn --interpolation Linear --winsorize-image-intensities [0.005,0.995] --use-histogram-matching 0 --transform Syn[0.1] --metric MI[${dwi2anat_ri},${anat},1,32] --convergence [150,1e-6,10] --shrink-factors 1 --smoothing-sigmas 0vox --masks ['brain_mask.nii.gz',${anat_mask}]


#apply inverse transform to get DWI2_anat_rigid --> DWI2Anat (total)
    antsApplyTransforms -d 3 -e 4 -i ${dwi2anat_ri} -r ${anat} -t reg/anat2dwi_syn0InverseWarp.nii.gz -o ${dwi2anat_syn}

#apply all transform on DWI to get DWI-->template
    antsApplyTransforms -d 3 -e 4 -i ${dwi2anat_syn} -r /project/4180000.24/analysis_wessel/DTI/template/DSURQE_100micron_average_LPI.nii.gz -t reg/anat2std1Warp.nii.gz -t reg/anat2std0GenericAffine.mat -o ${dwi2temp}

#slicer functions to check DWI2anat rigid, rigid+non-linear and DWI2temp transforms
slicer ${dwi2anat_ri} ${anat} -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard1.png ; slicer ${anat} ${dwi2anat_ri} -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard2.png ; pngappend highres2standard1.png - highres2standard2.png dwi2anat_ri_lin.png; rm -f sl?.png highres2standard2.png
rm highres2standard1.png

slicer ${dwi2anat_syn} ${anat} -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard1.png ; slicer ${anat} ${dwi2anat_syn} -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard2.png ; pngappend highres2standard1.png - highres2standard2.png dwi2anat_syn_lin.png; rm -f sl?.png highres2standard2.png
rm highres2standard1.png

    slicer ${dwi2temp} /project/4180000.24/analysis_wessel/DTI/template/DSURQE_100micron_average_LPI.nii.gz -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard1.png ; slicer /project/4180000.24/analysis_wessel/DTI/template/DSURQE_100micron_average_LPI.nii.gz ${dwi2temp} -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png -y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png -z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png ; pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png highres2standard2.png ; pngappend highres2standard1.png - highres2standard2.png dwi2template.png; rm -f sl?.png highres2standard2.png
rm highres2standard1.png

#compute dtifit

    dtifit -k ${dwi_noext}'_eddy.nii' -o dtifit -m brain_mask.nii.gz -r ${dwi_noext}'.bvec' -b ${dwi_noext}'.bval'

#apply transforms on FA map (this is an example of batch 1 pipeline)
    antsApplyTransforms -d 3 -i dtifit_FA.nii.gz -r /project/4180000.24/analysis_wessel/DTI/template/DSURQE_100micron_average_LPI.nii.gz -t reg/anat2std1Warp.nii.gz -t reg/anat2std0GenericAffine.mat -t reg/anat2dwi_syn0InverseWarp.nii.gz -t [reg/anat2dwi_ri0GenericAffine.mat,1] -o ${subses}'_dtifit_FA_reg.nii.gz'


#not used
    antsApplyTransforms -d 3 -i dtifit_MD.nii.gz -r /project/4180000.24/analysis_wessel/DTI/template/DSURQE_100micron_average_LPI.nii.gz -t reg/anat2std1Warp.nii.gz -t reg/anat2std0GenericAffine.mat -t reg/anat2dwi_syn0InverseWarp.nii.gz -t [reg/anat2dwi_ri0GenericAffine.mat,1] -o ${subses}'_dtifit_MD_reg.nii.gz'


#copy files from DTI analysis to dwi folder
    cp dwi2template.png /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//dwi
    cp dwi2anat_ri_lin.png /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//dwi
    cp dwi2anat_syn_lin.png /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//dwi
    cp ${subses}'_dtifit_FA_reg.nii.gz' /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//dwi
    cp ${subses}'_dtifit_MD_reg.nii.gz' /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//dwi

    #remove temp_data folder
    cd /project/4180000.24/analysis_wessel/DTI/analysis/LPI_253_DS_manualDWI//sub-aRi002//
    rm -r tmp_data/



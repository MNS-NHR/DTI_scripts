#first prepare the assets. copy all the anat and func files to new folders
cd /project/4180000.24/analysis_wessel/DTI/ben/

cp ../analysis/*/anat/*.nii.gz t2w/


#only keep first epi image to estimate mask
module load afni
ls | while read line ; do 3dresample -inset ${line}[0] -prefix tmp.nii.gz ; rm $line; mv tmp.nii.gz $line; rm tmp.nii.gz; done

#also deoblique and N4 correct the scans to make it easier. run it on epi and anat scans. 
ls | while read line ; do 3drefit -deoblique  -overwrite $line ; N4BiasFieldCorrection -d 3 -i $line -o tmp.nii.gz ; rm $line ; mv tmp.nii.gz $line ; done

#now the star of the show
#first install it with
module load anaconda3
conda create -y -n ben python=3.6
source activate ben
git clone  --branch doc https://github.com/yu02019/BEN.git
cd BEN
pip install -r requirements.txt


#later run if with
module load cuda/10.0 anaconda3
source activate ben

cd /project/4180000.24/analysis_wessel/DTI/ben/

#select subset of t2w and epi scans and make initial label that we will edit to refine the model
python BEN/BEN_infer.py -i train_b0 -o test_b0 -weight weight/aRi111924/.hdf5 -check RIA

#retrain the classifier after correcting the label maps. 
python BEN/BEN_DA.py -t train_b0 -l label_b0 -r raw_b0 -weight weight/Rat-T2WI-94T-CAMRI_epoch20__06230958/.hdf5 -prefix aRi111924_b0 -check RIA



#run the new models!!
python BEN/BEN_infer.py -i b0 -o b0_mask -weight weight/aRi111924/.hdf5 -check RIA


#put the masks back in place
cd /project/4180000.41/ben/
ls raw_mask/*.nii.gz | while read line
do

file_base=$(basename ${line})
file_noext="$(remove_ext $file_base)"

file_target="$(find ../orient_bids -name $file_base)"
file_target_noext="$(remove_ext $file_target)"

echo ${file_target}
cp $line $file_target_noext"_mask.nii.gz"
done

cd /project/4180000.41/ben/
ls t2w_mask/*.nii.gz | while read line
do

file_base=$(basename ${line})
file_noext="$(remove_ext $file_base)"

file_target="$(find ../bids -name $file_base)"
file_target_noext="$(remove_ext $file_target)"

cp $line $file_target_noext"_mask.nii.gz"
done


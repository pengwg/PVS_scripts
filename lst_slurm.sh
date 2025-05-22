#!/bin/bash

#SBATCH --array=1-140
#SBATCH --ntasks=1                   
#SBATCH --cpus-per-task=20            
#SBATCH --partition=gpu
#SBATCH --gpus=1

DATA_PATH=/home/pw0032/PVS_nii
FS_PATH=/home/pw0032/Data/batch1_output/FS

FILE_ID=$(printf "%03d" $SLURM_ARRAY_TASK_ID)

T1_VOL=$(find $FS_PATH/PVS_$FILE_ID/mri/ -type f -name nu.mgz | head -n 1)
FLAIR_VOL=$(find $DATA_PATH/ -type f -name "PVS_${FILE_ID}_T2_SPACE_FLAIR*.nii.gz" | head -n 1)
T2_VOL=$(find $DATA_PATH/ -type f \( -name "PVS_${FILE_ID}_T2_SPACE_AX*" -o -name "PVS_${FILE_ID}_T2_SPACE_SAG*" \) | head -n 1)

OUT_PATH=/home/pw0032/Data/batch1_output/LST/PVS_$FILE_ID

if ! [ -d $OUT_PATH ]; then
    mkdir $OUT_PATH
fi

mri_convert $T1_VOL $T1_VOL.nii.gz

singularity exec -e /cm/shared/containers/ANTs.sif antsRegistrationSyNQuick.sh -d 3 -t r -f $T1_VOL.nii.gz -m $FLAIR_VOL -o $OUT_PATH/flair2T1_ -n 20

source /home/pw0032/lst-ai/lst/bin/activate

echo "LST processing $OUT_PATH/fair2T1_Warped.nii.gz"
srun lst --t1 $T1_VOL.nii.gz --flair $OUT_PATH/flair2T1_Warped.nii.gz --output $OUT_PATH/ --temp $OUT_PATH/tmp/

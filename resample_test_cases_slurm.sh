#!/bin/bash

#SBATCH --array=1-9%9
#SBATCH --partition=defq
#SBATCH --ntasks=1                   
#SBATCH --cpus-per-task=1
#SBATCH --output=log/%x_%A_%a.out

DATA_PATH=/home/pw0032/Data/PVS_Data6
DEST=/home/pw0032/Data/nnUNet_data/inference_in_0.4
FILE_ID=$(printf "PVS_6_%03d" $SLURM_ARRAY_TASK_ID)

T2_VOL=$(find $DATA_PATH/ -type f \( -name "${FILE_ID}_T2_SPACE_AX*" -o -name "${FILE_ID}_T2_SPACE_SAG*" \) | head -n 1)
BASE=$(basename "$T2_VOL" .nii.gz)
      
singularity exec -e /cm/shared/containers/ANTs.sif \
    ResampleImageBySpacing 3 $T2_VOL $DEST/${BASE}_0000.nii.gz 0.4 0.4 0.4 0 0 0
        
singularity exec -e /cm/shared/containers/FSL.sif \
    fslmaths $DEST/${BASE}_0000.nii.gz $DEST/${BASE}_0000.nii.gz -odt short



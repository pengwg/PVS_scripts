#!/bin/bash

#SBATCH --array=1,5,24,25,30,31,38,61
#SBATCH --partition=defq
#SBATCH --ntasks=1                   
#SBATCH --cpus-per-task=8
#SBATCH --output=log/%x_%A_%a.out

DATA_PATH=/projects/2024-11_Perivascular_Space/PVS_Data5
export SUBJECTS_DIR=/projects/2024-11_Perivascular_Space/PVS_B5_Analysis/FS

FILE_ID=$(printf "PVS_5_%03d" $SLURM_ARRAY_TASK_ID)

T1_VOL=$(find $DATA_PATH/ -type f -name "${FILE_ID}_T1_RAGE_SAG.nii.gz" | head -n 1)
# T2_VOL=$(find $DATA_PATH/ -type f \( -name "${FILE_ID}_T2_SPACE_AX*" -o -name "${FILE_ID}_T2_SPACE_SAG*" \) | head -n 1)

cmd="recon-all -all -hires -parallel -cw256 -openmp 20 -i $T1_VOL -s $FILE_ID"

mri_convert $T1_VOL $SUBJECTS_DIR/${FILE_ID}_T1_prepped.nii.gz --conform
cmd="recon-all -all -hires -parallel -cw256 -openmp 20 -i $SUBJECTS_DIR/${FILE_ID}_T1_prepped.nii.gz -s $FILE_ID"

echo $cmd
srun $cmd

# Rerun synthmorph
# fs-synthmorph-reg --s PVS_$FILE_ID --threads 20 --i $SUBJECTS_DIR/PVS_$FILE_ID/mri/orig.mgz --test --force

# Rerun with T2
# srun recon-all -all -hires -parallel -cw256 -openmp 20 -T2 $T2_VOL -s PVS_$FILE_ID

#!/bin/bash

#SBATCH --array=91-140%30  
#SBATCH --partition=defq
#SBATCH --ntasks=1                   
#SBATCH --cpus-per-task=10            

FILE_PATH=/home/pw0032/PVS_nii

mapfile -t FILES_NUM < file_numbers.txt

TASK_ID=$(printf "%03d" $SLURM_ARRAY_TASK_ID)
# TASK_ID=${FILES_NUM[$SLURM_ARRAY_TASK_ID]}

T1_VOL=PVS_${TASK_ID}_T1_RAGE_SAG.nii.gz
T2_VOL=PVS_${TASK_ID}_T2_SPACE_AX.nii.gz
FLAIR_VOL=PVS_${TASK_ID}_T2_SPACE_FLAIR_AX.nii.gz

# srun recon-all -all -hires -parallel -openmp 10 -i "$FILE_PATH/$T1_VOL" -s PVS_$TASK_ID

# Rerun with T2
srun recon-all -all -hires -parallel -openmp 10 -T2 "$FILE_PATH/$T2_VOL" -s PVS_$TASK_ID

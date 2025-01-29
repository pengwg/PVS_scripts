#!/bin/bash

#SBATCH --array=1-140%5  
#SBATCH --ntasks=1                   
#SBATCH --cpus-per-task=30            
#SBATCH --partition=gpu
#SBATCH --gpus=2

FILE_PATH=/home/pw0032/PVS_nii

TASK_ID=$(printf "%03d" $SLURM_ARRAY_TASK_ID)

T1_VOL=PVS_${TASK_ID}_T1_RAGE_SAG.nii.gz
T2_VOL=PVS_${TASK_ID}_T2_SPACE_AX.nii.gz
FLAIR_VOL=PVS_${TASK_ID}_T2_SPACE_FLAIR_AX.nii.gz

source /home/pw0032/lst-ai/lst/bin/activate

srun lst --t1 $FILE_PATH/$T1_VOL --flair $FILE_PATH/$FLAIR_VOL --output /projects/2024-11_Perivascular_Space/LST/${TASK_ID} --temp /projects/2024-11_Perivascular_Space/LST/temp

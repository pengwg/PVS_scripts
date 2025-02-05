#!/bin/bash

#SBATCH --array=1-140
#SBATCH --ntasks=1                   
#SBATCH --cpus-per-task=40            
#SBATCH --partition=gpu
#SBATCH --gpus=2

DATA_PATH=/home/pw0032/PVS_nii

# mapfile -t FILES_NUM < lst_work_number.txt
# FILE_ID=$(echo "${FILES_NUM[$SLURM_ARRAY_TASK_ID]}" | xargs)
FILE_ID=$(printf "%03d" $SLURM_ARRAY_TASK_ID)

T1_VOL=$(find $DATA_PATH/ -type f -name "PVS_${FILE_ID}_T1_RAGE_*.nii.gz" | head -n 1)
FLAIR_VOL=$(find $DATA_PATH/ -type f -name "PVS_${FILE_ID}_T2_SPACE_FLAIR*.nii.gz" | head -n 1)
T2_VOL=$(find $DATA_PATH/ -type f \( -name "PVS_${FILE_ID}_T2_SPACE_AX*" -o -name "PVS_${FILE_ID}_T2_SPACE_SAG*" \) | head -n 1)

source /home/pw0032/lst-ai/lst/bin/activate

echo "Processing PVS_$FILE_ID"
srun lst --t1 $T1_VOL --flair $FLAIR_VOL --output /projects/2024-11_Perivascular_Space/LST/${FILE_ID} --temp /projects/2024-11_Perivascular_Space/LST/temp-$FILE_ID

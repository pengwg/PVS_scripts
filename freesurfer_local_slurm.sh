#!/bin/bash

#SBATCH --array=0-8  
#SBATCH --partition=defq
#SBATCH --ntasks=1                   
#SBATCH --cpus-per-task=20       

DATA_PATH=/projects/2024-11_Perivascular_Space/PVS_Data/PVS_nii

mapfile -t FILES_NUM < /home/pw0032/scripts/file_numbers.txt

# FILE_ID=$(printf "%03d" $SLURM_ARRAY_TASK_ID)
FILE_ID=$(echo "${FILES_NUM[$SLURM_ARRAY_TASK_ID]}" | xargs)

T1_VOL=$(find $DATA_PATH/ -type f -name "PVS_${FILE_ID}_T1_RAGE_*.nii.gz" | head -n 1)
T2_VOL=$(find $DATA_PATH/ -type f \( -name "PVS_${FILE_ID}_T2_SPACE_AX*" -o -name "PVS_${FILE_ID}_T2_SPACE_SAG*" \) | head -n 1)

echo "recon-all -all -hires -parallel -cw256 -openmp 20 -i $T1_VOL -T2 $T2_VOL -s PVS_$FILE_ID"
srun recon-all -all -hires -parallel -cw256 -openmp 20 -i $T1_VOL -T2 $T2_VOL -s PVS_$FILE_ID

# Rerun with T2
# srun recon-all -all -hires -parallel -cw256 -openmp 20 -T2 $T2_VOL -s PVS_$FILE_ID

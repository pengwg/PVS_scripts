#!/bin/bash

#SBATCH --array=1-54%8
#SBATCH --partition=defq
#SBATCH --ntasks=1                   
#SBATCH --cpus-per-task=20       

DATA_PATH=/projects/2024-11_Perivascular_Space/PVS_Data1
export SUBJECTS_DIR=/projects/2024-11_Perivascular_Space/PVS_B2_Analysis/FS

FILE_ID=$(printf "%03d" $SLURM_ARRAY_TASK_ID)

T1_VOL=$(find $DATA_PATH/ -type f -name "PVS_${FILE_ID}_T1_RAGE_*.nii.gz" | head -n 1)
T2_VOL=$(find $DATA_PATH/ -type f \( -name "PVS_${FILE_ID}_T2_SPACE_AX*" -o -name "PVS_${FILE_ID}_T2_SPACE_SAG*" \) | head -n 1)

echo "recon-all -all -hires -parallel -cw256 -openmp 20 -i $T1_VOL -T2 $T2_VOL -s PVS_$FILE_ID"
srun recon-all -all -hires -parallel -cw256 -openmp 20 -i $T1_VOL -T2 $T2_VOL -s PVS_$FILE_ID

# Rerun with T2
# srun recon-all -all -hires -parallel -cw256 -openmp 20 -T2 $T2_VOL -s PVS_$FILE_ID

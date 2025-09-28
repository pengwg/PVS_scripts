#!/bin/bash

#SBATCH --array=1-45%8
#SBATCH --partition=defq
#SBATCH --ntasks=1                   
#SBATCH --cpus-per-task=20       

DATA_PATH=/projects/2024-11_Perivascular_Space/PVS_Data4
export SUBJECTS_DIR=/projects/2024-11_Perivascular_Space/PVS_B4_Analysis/FS

FILE_ID=$(printf "PVS_4_%03d" $SLURM_ARRAY_TASK_ID)

T1_VOL=$(find $DATA_PATH/$FILE_ID/ -type f -name "${FILE_ID}_T1_RAGE_*.nii" | head -n 1)
T2_VOL=$(find $DATA_PATH/$FILE_ID/ -type f \( -name "${FILE_ID}_T2_SPACE_AX*" -o -name "${FILE_ID}_T2_SPACE_SAG*" \) | head -n 1)

echo "recon-all -all -hires -parallel -cw256 -openmp 20 -i $T1_VOL -T2 $T2_VOL -T2pial -s $FILE_ID"
srun recon-all -all -hires -parallel -cw256 -openmp 20 -i $T1_VOL -T2 $T2_VOL -T2pial -s $FILE_ID
#srun recon-all -parallel -cw256 -openmp 20 -s $FILE_ID -autorecon2 -autorecon3 -T2pial -no-isrunning

# Rerun synthmorph
# fs-synthmorph-reg --s PVS_$FILE_ID --threads 20 --i $SUBJECTS_DIR/PVS_$FILE_ID/mri/orig.mgz --test --force

# Rerun with T2
# srun recon-all -all -hires -parallel -cw256 -openmp 20 -T2 $T2_VOL -s PVS_$FILE_ID

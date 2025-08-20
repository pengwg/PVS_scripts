#!/bin/bash

SLURM_ARRAY_TASK_ID=108

DATA_PATH=/projects/2024-11_Perivascular_Space/PVS_Data1
# export SUBJECTS_DIR=/projects/2024-11_Perivascular_Space/PVS_B1_Analysis/FS_skullstrip
export SUBJECTS_DIR=/tm/Data/PVS/FS-skullstrip

FILE_ID=$(printf "PVS_%03d" $SLURM_ARRAY_TASK_ID)

T1_VOL=$(find $DATA_PATH/ -type f -name "${FILE_ID}_T1_RAGE_*.nii.gz" | head -n 1)
T2_VOL=$(find $DATA_PATH/ -type f \( -name "${FILE_ID}_T2_SPACE_AX*" -o -name "${FILE_ID}_T2_SPACE_SAG*" \) | head -n 1)
T1_NII=$SUBJECTS_DIR/$FILE_ID/mri/orig.nii.gz

mri_convert $SUBJECTS_DIR/$FILE_ID/mri/orig.mgz $T1_NII

# singularity exec -e /cm/shared/containers/ANTs.sif antsBrainExtraction.sh \
antsBrainExtraction.sh \
  -d 3 \
  -a $T1_NII \
  -e tpl-OASIS30ANTs_res-01_T1w.nii.gz \
  -m tpl-OASIS30ANTs_res-01_desc-brain_mask.nii.gz \
  -o $SUBJECTS_DIR/$FILE_ID/ants/ants_

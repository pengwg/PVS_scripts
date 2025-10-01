#!/usr/bin/bash

#SBATCH --array=1-54%20
#SBATCH --partition=defq
#SBATCH --ntasks=1                   
#SBATCH --cpus-per-task=1       

DATA_PATH=/projects/2024-11_Perivascular_Space/PVS_Data2
export SUBJECTS_DIR=/projects/2024-11_Perivascular_Space/PVS_B2_Analysis/FS

FILE_ID=$(printf "%03d" $SLURM_ARRAY_TASK_ID)

FS_MRI_DIR=/projects/2024-11_Perivascular_Space/PVS_B2_Analysis/FS/PVS_2_${FILE_ID}/mri
OUTPUT_DIR=/projects/2024-11_Perivascular_Space/PVS_B2_Analysis/Frangi_pruned/PVS_2_${FILE_ID}

if ! [ -d $OUTPUT_DIR ]; then
    mkdir $OUTPUT_DIR
fi

T2_VOL=$(find $DATA_PATH/ -type f \( -name "PVS_2_${FILE_ID}_T2_SPACE_AX*" -o -name "PVS_2_${FILE_ID}_T2_SPACE_SAG*" \) | head -n 1)
mri_convert $FS_MRI_DIR/aseg.mgz $OUTPUT_DIR/aseg.nii.gz
singularity exec -e /cm/shared/containers/ANTs.sif ResampleImageBySpacing 3 $OUTPUT_DIR/aseg.nii.gz $OUTPUT_DIR/aseg.nii.gz 0.4 0.4 0.4 0 0 1
mri_vol2vol --lta $FS_MRI_DIR/transforms/T2raw.lta --mov $T2_VOL --targ $OUTPUT_DIR/aseg.nii.gz --o $OUTPUT_DIR/T2_iso.nii.gz

# Create CSO mask in native space
TRANSFORM_PATH=$FS_MRI_DIR/transforms/synthmorph.1.0mm.1.0mm
mri_synthmorph apply -m nearest -t uint8 $TRANSFORM_PATH/warp.to.mni152.1.0mm.1.0mm.inv.nii.gz cso_mask_mni.nii.gz $OUTPUT_DIR/cso_mask_native.nii.gz
singularity exec -e /cm/shared/containers/ANTs.sif ResampleImageBySpacing 3 $OUTPUT_DIR/cso_mask_native.nii.gz $OUTPUT_DIR/cso_mask_native.nii.gz 0.4 0.4 0.4 0 0 1


#!/usr/bin/bash

#SBATCH --array=1-140%20
#SBATCH --partition=defq
#SBATCH --ntasks=1                   
#SBATCH --cpus-per-task=1       

DATA_PATH=/projects/2024-11_Perivascular_Space/PVS_Data1
export SUBJECTS_DIR=/projects/2024-11_Perivascular_Space/PVS_B1_Analysis/FS

FILE_ID=$(printf "%03d" $SLURM_ARRAY_TASK_ID)

DATA_PATH=/projects/2024-11_Perivascular_Space/PVS_Data1
FS_MRI_DIR=/projects/2024-11_Perivascular_Space/PVS_B1_Analysis/FS/PVS_${FILE_ID}/mri
OUTPUT_DIR=/projects/2024-11_Perivascular_Space/PVS_B1_Analysis/Frangi_pruned/PVS_${FILE_ID}

if ! [ -d $OUTPUT_DIR ]; then
    mkdir $OUTPUT_DIR
fi

T2_VOL=$(find $DATA_PATH/ -type f \( -name "PVS_${FILE_ID}_T2_SPACE_AX*" -o -name "PVS_${FILE_ID}_T2_SPACE_SAG*" \) | head -n 1)
mri_convert $FS_MRI_DIR/aseg.mgz $OUTPUT_DIR/aseg.nii.gz

# Resample aseg to 0.4 isotropic voxel
singularity exec -e /cm/shared/containers/ANTs.sif ResampleImageBySpacing 3 $OUTPUT_DIR/aseg.nii.gz $OUTPUT_DIR/aseg_iso.nii.gz 0.4 0.4 0.4 0 0 1

# Transform T2 to T1 space
mri_vol2vol --lta $FS_MRI_DIR/transforms/T2raw.lta --mov $T2_VOL --targ $OUTPUT_DIR/aseg_iso.nii.gz --o $OUTPUT_DIR/T2toT1_iso.nii.gz

# Create CSO mask in T1 native space
TRANSFORM_PATH=$FS_MRI_DIR/transforms/synthmorph.1.0mm.1.0mm
mri_synthmorph apply -m nearest -t uint8 $TRANSFORM_PATH/warp.to.mni152.1.0mm.1.0mm.inv.nii.gz cso_mask_mni.nii.gz $OUTPUT_DIR/cso_mask_T1.nii.gz
mri_vol2vol --nearest --regheader --mov $OUTPUT_DIR/cso_mask_T1.nii.gz --targ $OUTPUT_DIR/aseg_iso.nii.gz --o $OUTPUT_DIR/cso_mask_iso.nii.gz

# Create aseg and CSO mask in original T2 native space
mri_vol2vol --nearest --lta-inv $FS_MRI_DIR/transforms/T2raw.lta --targ $T2_VOL --mov $OUTPUT_DIR/aseg.nii.gz --o $OUTPUT_DIR/aseg_T2.nii.gz
mri_vol2vol --nearest --lta-inv $FS_MRI_DIR/transforms/T2raw.lta --targ $T2_VOL --mov $OUTPUT_DIR/cso_mask_T1.nii.gz --o $OUTPUT_DIR/cso_mask_T2.nii.gz

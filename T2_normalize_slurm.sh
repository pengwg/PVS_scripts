#!/usr/bin/bash
#SBATCH --array=1-64%15
#SBATCH --partition=defq
#SBATCH --ntasks=1                   
#SBATCH --cpus-per-task=4
#SBATCH --output=log/%x_%A_%a.out

cores=4
DATA_PATH=/projects/2024-11_Perivascular_Space/PVS_Data5
FILE_ID=$(printf "PVS_5_%03d" $SLURM_ARRAY_TASK_ID)
FS_MRI_DIR=/projects/2024-11_Perivascular_Space/PVS_B5_Analysis/FS/${FILE_ID}/mri
OUTPUT_DIR=/projects/2024-11_Perivascular_Space/PVS_B5_Analysis/${FILE_ID}

mkdir -p $OUTPUT_DIR

T2_VOL=$(find $DATA_PATH/ -type f \( -name "${FILE_ID}_T2_SPACE_AX*" -o -name "${FILE_ID}_T2_SPACE_SAG*" \) | head -n 1)

if ! [ -f "$OUTPUT_DIR/cso_mask_iso.nii.gz" ]; then
    mri_convert $FS_MRI_DIR/aseg.mgz $OUTPUT_DIR/aseg.nii.gz

    # Resample aseg to 0.4 isotropic voxel
    singularity exec -e /cm/shared/containers/ANTs.sif ResampleImageBySpacing 3 $OUTPUT_DIR/aseg.nii.gz $OUTPUT_DIR/aseg_iso.nii.gz 0.4 0.4 0.4 0 0 1

    # Transform T2 to T1 space
    # mri_vol2vol --lta $FS_MRI_DIR/transforms/T2raw.lta --mov $T2_VOL --targ $OUTPUT_DIR/aseg_iso.nii.gz --o $OUTPUT_DIR/T2toT1_iso.nii.gz

    # Create CSO mask in T1 native space
    TRANSFORM_PATH=$FS_MRI_DIR/transforms/synthmorph.1.0mm.1.0mm
    mri_synthmorph apply -m nearest -t uint8 $TRANSFORM_PATH/warp.to.mni152.1.0mm.1.0mm.inv.nii.gz cso_mask_mni.nii.gz $OUTPUT_DIR/cso_mask_T1.nii.gz
    mri_vol2vol --nearest --regheader --mov $OUTPUT_DIR/cso_mask_T1.nii.gz --targ $OUTPUT_DIR/aseg_iso.nii.gz --o $OUTPUT_DIR/cso_mask_iso.nii.gz
fi

if ! [ -f "$OUTPUT_DIR/T2toT1.lta" ]; then
    mri_synthmorph register -m rigid -t $OUTPUT_DIR/T2toT1.lta -T $OUTPUT_DIR/T2toT1.inv.lta $T2_VOL $FS_MRI_DIR/orig.mgz -j $cores
fi

# Create wmparc and CSO mask in original T2 native space
if ! [ -f "$OUTPUT_DIR/wmparc_T2.nii.gz" ]; then
    mri_vol2vol --nearest --lta-inv $OUTPUT_DIR/T2toT1.lta --targ $T2_VOL --mov $FS_MRI_DIR/wmparc.mgz --o $OUTPUT_DIR/wmparc_T2.nii.gz
fi

if ! [ -f "$OUTPUT_DIR/aseg_T2.nii.gz" ]; then
    mri_vol2vol --nearest --lta-inv $OUTPUT_DIR/T2toT1.lta --targ $T2_VOL --mov $FS_MRI_DIR/aseg.mgz --o $OUTPUT_DIR/aseg_T2.nii.gz
fi

if ! [ -f "$OUTPUT_DIR/cso_mask_T2.nii.gz" ]; then
    mri_vol2vol --nearest --lta-inv $OUTPUT_DIR/T2toT1.lta --targ $T2_VOL --mov $OUTPUT_DIR/cso_mask_T1.nii.gz --o $OUTPUT_DIR/cso_mask_T2.nii.gz
fi

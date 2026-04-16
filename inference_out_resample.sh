#!/bin/bash

s=0.4

data_path=$HOME/Data/nnUNet_data/inference_out_$s
out_path=$data_path/T2_SPACE
ref_path=$HOME/Data/PVS_Data6

mkdir -p "$out_path"

for f in $data_path/PVS_6_*.nii.gz; do
    base=$(basename "$f" .nii.gz)
    mri_vol2vol --nearest --regheader --keep-precision --mov $f --targ $ref_path/${base}.nii.gz --o $out_path/$base.nii.gz
done



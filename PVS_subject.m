function PVS_subject(id)

addpath('filters/frangi_filter_version2a/')

data_path = '/home/pw0032/FS';
out_path = '/projects/2024-11_Perivascular_Space/batch1_output/PVS_vessel';

Options.BlackWhite = false;
Options.FrangiScaleRange = [0.1 4];
Options.FrangiScaleRatio = 0.3;
Options.FrangiC = 60;


subject = sprintf('PVS_%03d', id);
T2_fs = [data_path '/' subject '/mri/T2.prenorm.mgz'];
T2_nii = [data_path '/' subject '/mri/T2.prenorm.nii'];
seg_fs = [data_path '/' subject '/mri/aparc+aseg.mgz'];
seg_nii = [data_path '/' subject '/mri/aparc+aseg.nii'];

if exist(T2_fs, 'file') ~= 2
    return
end

if exist(T2_nii, 'file') ~= 2
    system(['mri_convert ' T2_fs ' ' T2_nii]);
end

if exist(seg_nii, 'file') ~= 2
    system(['mri_convert ' seg_fs ' ' seg_nii]);
end

disp(['Measure  ' subject '...' ])

info = niftiinfo(T2_nii);
T2_vol = niftiread(info);

% [J,Scale,Vx,Vy,Vz] = FrangiFilter3D(T2_vol, Options);

% niftiwrite(J, [out_path '/' subject '_vesselnessC60'], info, 'Compressed',true)
% niftiwrite(Scale, [out_path '/' subject '_ScaleC60'], info, 'Compressed',true)

J = niftiread([out_path '/' subject '_vesselnessC60.nii.gz']);
% Scale = niftiread([out_path '/' subject '_ScaleC60.nii.gz']);
vessels = J;

threshold = 20e-4;
vessels(vessels < threshold) = 0;
vessels(vessels >= threshold) = 1;

seg_vol = niftiread(seg_nii);
wm_mask = (seg_vol == 2) | (seg_vol == 41);
wm_mask = imerode(wm_mask, strel('sphere',3));
bg_mask = ismember(seg_vol, [11, 12, 13, 26, 50, 51, 52, 58]);

vessels(~(wm_mask | bg_mask)) = 0;

niftiwrite(vessels, [out_path '/' subject '_vesselmask'], info, 'Compressed',true)

return

clear

p = gcp('nocreate');
if isempty(p)
    parpool(12);
end

parfor n = 1 : 140
    PVS_subject(n)
end

return


%%
function PVS_subject(id)

addpath('filters/frangi_filter_version2a/')

data_path = '/tm/Data/PVS';

FS_path = [data_path '/FS'];
out_path = [data_path '/Frangi'];
lst_path = [data_path '/LST'];

Options.BlackWhite = false;
Options.FrangiScaleRange = [0.5 4];
Options.FrangiScaleRatio = 0.5;
Options.FrangiC = 60;
threshold = 5e-3;

subject = sprintf('PVS_%03d', id);
T2_fs = [FS_path '/' subject '/mri/T2.prenorm.mgz'];
T2_nii = [FS_path '/' subject '/mri/T2.prenorm.nii'];
seg_fs = [FS_path '/' subject '/mri/aparc+aseg.mgz'];
seg_nii = [FS_path '/' subject '/mri/aparc+aseg.nii'];

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
out_name = [out_path '/' subject '_vesselness_C200'];

if exist([out_name, '.nii.gz'], 'file') == 2
    vessleness = niftiread([out_name, '.nii.gz']);
else
    T2_vol = niftiread(info);
    [vessleness,Scale,~,~,~] = FrangiFilter3D(T2_vol, Options);

    niftiwrite(vessleness, out_name, info, 'Compressed',true)
    % niftiwrite(Scale, [out_path '/' subject '_ScaleC60'], info, 'Compressed',true)
end

wmh = niftiread([lst_path '/' subject '/space-flair_seg-lst.nii.gz']);

seg_vol = niftiread(seg_nii);
ventricals = ismember(seg_vol, [4, 5, 14, 43, 44]);
ventricals = imdilate(ventricals, strel('sphere', 5));
% hippocampus = ismember(seg_vol, [17, 53]);

wmbg_mask = ismember(seg_vol, [2, 41, 11, 12, 13, 26, 50, 51, 52, 58]);
wmbg_mask(ventricals) = 0;

[vesselness_wmbg, vesselmap_wmbg] = vessel_region_threshold(vessleness, wmbg_mask, threshold);
niftiwrite(vesselness_wmbg, [out_path '/' subject '_vesselness_wmbg'], info, 'Compressed',true)
niftiwrite(vesselmap_wmbg, [out_path '/' subject '_vsmask_wmbg'], info, 'Compressed',true)

vesselmap_nawmbg = vesselmap_wmbg;
vesselmap_nawmbg(logical(wmh)) = 0;
niftiwrite(vesselmap_nawmbg, [out_path '/' subject '_vsmask_nawmbg'], info, 'Compressed',true)

wm_mask = ismember(seg_vol, [2, 41]);

vesselmap_wm = vesselmap_wmbg;
vesselmap_wm(~logical(wm_mask)) = 0;
niftiwrite(vesselmap_wm, [out_path '/' subject '_vsmask_wm'], info, 'Compressed',true)

vesselmap_wm(logical(wmh)) = 0;
niftiwrite(vesselmap_wm, [out_path '/' subject '_vsmask_nawm'], info, 'Compressed',true)

vesselmap_bg = vesselmap_wmbg;
vesselmap_bg(logical(wm_mask)) = 0;
niftiwrite(vesselmap_bg, [out_path '/' subject '_vsmask_bg'], info, 'Compressed',true)


% caudate_mask = ismember(seg_vol, [11, 50]);
% caudate_mask(ventricals) = 0;
% 
% putamen_mask = ismember(seg_vol, [12, 51]);
% putamen_mask(ventricals) = 0;
% 
% pallidum_mask = ismember(seg_vol, [13, 52]);
% pallidum_mask(ventricals) = 0;
% 
% accumbens_mask = ismember(seg_vol, [26, 58]);
% accumbens_mask(ventricals) = 0;

end


%%
function [vesselness_region, vesselmap_region] = vessel_region_threshold(vesselness, region_mask, threshold)

vesselness_region = vesselness;
vesselness_region(~region_mask) = 0;

vesselmap_region = vesselness_region;
vesselmap_region(vesselmap_region < threshold) = 0;
vesselmap_region(vesselmap_region >= threshold) = 1;

end


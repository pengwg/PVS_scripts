clear

addpath('matlab_auxiliary/')

data_path = {'/projects/2024-11_Perivascular_Space/PVS_B1_Analysis', ...
             '/projects/2024-11_Perivascular_Space/PVS_B2_Analysis', ...
             '/projects/2024-11_Perivascular_Space/PVS_B4_Analysis'};

PVS_path = '/home/pw0032/Data/nnUNet_data/inference_pvs';

num_subjects = [140, 54, 45];
batch_id_spec = {'PVS_%03d', 'PVS_2_%03d', 'PVS_4_%03d'};

p = gcp('nocreate');
if isempty(p)
    parpool(16);
end

PVS_measure_region(PVS_path, data_path, num_subjects, batch_id_spec)

return


function PVS_measure_region(PVS_path, data_path, num_subjects, batch_id_spec)

total_num_subjects = sum(num_subjects);
subjectIDs = cell(total_num_subjects, 1);

eTIV = zeros(total_num_subjects, 1);
vol_brainmask = zeros(total_num_subjects, 1);
stats = zeros(total_num_subjects, 15);

vol_wm = zeros(total_num_subjects, 1);
vol_cso = vol_wm;
vol_frontal = vol_wm;
vol_parietal = vol_wm;
vol_occipital = vol_wm;
vol_temporal = vol_wm;

pvsVol_wm = zeros(total_num_subjects, 1);
pvsVol_cso = pvsVol_wm;
pvsVol_frontal = pvsVol_wm;
pvsVol_parietal = pvsVol_wm;
pvsVol_occipital = pvsVol_wm;
pvsVol_temporal = pvsVol_wm;

numPVS_wm = zeros(total_num_subjects, 1);
numPVS_cso = numPVS_wm;
numPVS_frontal = numPVS_wm;
numPVS_parietal = numPVS_wm;
numPVS_occipital = numPVS_wm;
numPVS_temporal = numPVS_wm;

frontal_labels = [3003 3012 3014 3018 3019 3020 3024 3027 3028 3032 ...
                  4003 4012 4014 4018 4019 4020 4024 4027 4028 4032];

parietal_labels = [3008 3017 3022 3025 3029 3031 4008 4017 4022 4025 4029 4031];

occipital_labels = [3005 3011 3013 3021 4005 4011 4013 4021];

temporal_labels = [3001 3006 3007 3009 3015 3016 3030 3033 3034 ...
                   4001 4006 4007 4009 4015 4016 4030 4033 4034];
                 
group_i0 = 0;
for k = 1 : length(num_subjects)
    FS_path = [data_path{k} '/FS'];
    data_path_analysis = [data_path{k} '/Frangi_pruned'];
    batch_id_spec_now = batch_id_spec{k};

    parfor n = group_i0 + 1 : group_i0 + num_subjects(k)
        subject = sprintf(batch_id_spec_now, n - group_i0);
        subjectIDs{n, 1} = subject;

        pvs_files = dir(fullfile(PVS_path, [subject '*.nii.gz']));
        
        if isempty(pvs_files)
            disp([subject ' not found!'])
            continue
        end
        pvs_mask_file = fullfile(PVS_path, pvs_files(1).name);

        disp(['Measure ' subject ' ...' ])
		
        brain_fs = [FS_path '/' subject '/mri/brainmask.mgz'];
        brain_nii = [FS_path '/' subject '/mri/brainmask.nii.gz'];
        aseg_stats = [FS_path '/' subject '/stats/aseg.stats'];
        aseg_nii = [data_path_analysis '/' subject '/aseg_T2.nii.gz'];
        wmparc_nii = [data_path_analysis '/' subject '/wmparc_T2.nii.gz'];
        cso_nii = [data_path_analysis '/' subject '/cso_mask_T2.nii.gz'];

        if exist(aseg_stats, 'file') ~= 2
            disp([subject ' aseg.stats not found!'])
            continue
        end
        
        if exist(brain_fs, 'file') ~= 2
            disp([subject ' brainmask not found!'])
            continue
        end
        
        if exist(brain_nii, 'file') ~= 2
            system(['mri_convert ' brain_fs ' ' brain_nii]);
        end

        info = niftiinfo(brain_nii);
        brain = niftiread(info);
        vol_brainmask(n) = nnz(brain > 0) * prod(info.PixelDimensions);
        eTIV(n) = get_eTIV(aseg_stats);

        info = niftiinfo(aseg_nii);
        aseg_vol = niftiread(info);
        wm_mask = ismember(aseg_vol, [2, 41]);        
        
        wmparc_vol = niftiread(wmparc_nii);
        frontal_mask = ismember(wmparc_vol, frontal_labels);
        parietal_mask = ismember(wmparc_vol, parietal_labels);
        occipital_mask = ismember(wmparc_vol, occipital_labels);
        temporal_mask = ismember(wmparc_vol, temporal_labels);
        cso_mask = niftiread(cso_nii);
        cso_mask(~wm_mask) = 0;
        
        niftiwrite(single(frontal_mask) + 2 * single(parietal_mask) + 3 * single(occipital_mask) + 4 * single(temporal_mask), ...
            [data_path_analysis '/' subject '/lobes_T2.nii.gz'], info)
        
        vol_wm(n) = nnz(wm_mask) * prod(info.PixelDimensions);
        vol_cso(n) = nnz(cso_mask) * prod(info.PixelDimensions);
        vol_frontal(n) = nnz(frontal_mask) * prod(info.PixelDimensions);
        vol_parietal(n) = nnz(parietal_mask) * prod(info.PixelDimensions);
        vol_occipital(n) = nnz(occipital_mask) * prod(info.PixelDimensions);
        vol_temporal(n) = nnz(temporal_mask) * prod(info.PixelDimensions);
        
        info = niftiinfo(pvs_mask_file);
        pvs_mask_vol = niftiread(info);

        pvs_wm_vol = pvs_mask_vol .* uint8(wm_mask);
        pvs_cso_vol = pvs_mask_vol .* uint8(cso_mask);
        pvs_frontal_vol = pvs_mask_vol .* uint8(frontal_mask);
        pvs_parietal_vol = pvs_mask_vol .* uint8(parietal_mask);
        pvs_occipital_vol = pvs_mask_vol .* uint8(occipital_mask);
        pvs_temporal_vol = pvs_mask_vol .* uint8(temporal_mask);
        
        [stats_subject, measure_all] = measurePVSstats(pvs_wm_vol, info.PixelDimensions);
        if isempty(measure_all)
            disp(['No PVS detected in ' subject])
            continue
        end
        stats(n, :) = stats_subject';
        numPVS_wm(n) = size(measure_all, 1);
        pvsLength = measure_all(:, 1);
        pvsWidth = measure_all(:, 2);
        pvsVolume = measure_all(:, 3);
        pvsVol_wm(n) = sum(pvsVolume);
        writetable(table(pvsLength, pvsWidth, pvsVolume), sprintf('%s/%s/PVS%d_%03d_wm_nnUNet.xlsx', data_path_analysis, subject, k, n), 'WriteMode', 'replacefile');

        [pvsVol_cso(n), numPVS_cso(n)] = measurePVS(pvs_cso_vol, info.PixelDimensions);       
        [pvsVol_frontal(n), numPVS_frontal(n)] = measurePVS(pvs_frontal_vol, info.PixelDimensions);
        [pvsVol_parietal(n), numPVS_parietal(n)] = measurePVS(pvs_parietal_vol, info.PixelDimensions);
        [pvsVol_occipital(n),  numPVS_occipital(n)] = measurePVS(pvs_occipital_vol, info.PixelDimensions);
        [pvsVol_temporal(n), numPVS_temporal(n)] = measurePVS(pvs_temporal_vol, info.PixelDimensions);

    end
    group_i0 = group_i0 + num_subjects(k);
end

% lengthMean = stats(:, 1);
% lengthMedian = stats(:, 2);
% lengthStd = stats(:, 3);
% lengthPrc25 = stats(:, 4);
% lengthPrc75 = stats(:, 5);
% 
% widthMean = stats(:, 6);
% widthMedian = stats(:, 7);
% widthStd = stats(:, 8);
% widthPrc25 = stats(:, 9);
% widthPrc75 = stats(:, 10);
% 
% volMean = stats(:, 11);
% volMedian = stats(:, 12);
% volStd = stats(:, 13);
% volPrc25 = stats(:, 14);
% volPrc75 = stats(:, 15);

T = table(subjectIDs, eTIV, vol_brainmask, vol_wm, pvsVol_wm, numPVS_wm, vol_cso, pvsVol_cso, numPVS_cso, ...
          vol_frontal, pvsVol_frontal, numPVS_frontal, vol_parietal, pvsVol_parietal, numPVS_parietal, ...
          vol_occipital, pvsVol_occipital, numPVS_occipital, vol_temporal, pvsVol_temporal, numPVS_temporal);

writetable(T, ['PVS_stats_nnUNet.xlsx'], 'WriteMode', 'replacefile')

end

%%
function eTIV = get_eTIV(stats_file)

fid = fopen(stats_file);

eTIV = NaN;
tline = fgetl(fid);

while ischar(tline)
    if contains(tline, 'EstimatedTotalIntraCranialVol')
        parts = strsplit(tline, ',');
        eTIV = str2double(strtrim(parts{4}));
        break;
    end
    tline = fgetl(fid);
end

fclose(fid);

% disp(['eTIV = ', num2str(eTIV), ' mm^3']);

end

%%
function [pvsVol, numPVS] = measurePVS(pvs_vol, pixelDimensions)

[~, measure_all] = measurePVSstats(pvs_vol, pixelDimensions);

if ~isempty(measure_all)
    numPVS = size(measure_all, 1);
    pvsVol = sum(measure_all(:, 3));
else
    numPVS = 0;
    pvsVol = 0;
end

end

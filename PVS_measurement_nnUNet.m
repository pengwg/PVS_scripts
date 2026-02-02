clear

addpath('matlab_auxiliary/')

data_path = {'/projects/2024-11_Perivascular_Space/PVS_B1_Analysis', ...
             '/projects/2024-11_Perivascular_Space/PVS_B2_Analysis', ...
             '/projects/2024-11_Perivascular_Space/PVS_B4_Analysis'};

PVS_path = '/home/pw0032/Data/nnUNet_data/inference_out_0.4/T2_SPACE';

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

WM = repmat(struct('Vol', 0, 'numPVS', 0, 'pvsVol', 0, 'pvsVolMean', 0, 'pvsVolMedian', 0, 'lengthMean', 0, 'lengthMedian', 0, 'widthMean', 0, 'widthMedian', 0), total_num_subjects, 1);
CSO = WM;
Frontal = WM;
Parietal = WM;
Occipital = WM;
Temporal = WM;

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
        
        info = niftiinfo(pvs_mask_file);
        pvs_mask_vol = niftiread(info);
        
        [~, measure_all] = measurePVSstats(pvs_mask_vol.*uint8(wm_mask), info.PixelDimensions);
        pvsLength = measure_all(:, 1);
        pvsWidth = measure_all(:, 2);
        pvsVolume = measure_all(:, 3);
        writetable(table(pvsLength, pvsWidth, pvsVolume), sprintf('%s/%s/PVS%d_%03d_wm_nnUNet.xlsx', data_path_analysis, subject, k, n), 'WriteMode', 'replacefile');

        WM(n) = measurePVS(pvs_mask_vol, wm_mask, info.PixelDimensions);
        CSO(n) = measurePVS(pvs_mask_vol, cso_mask, info.PixelDimensions);       
        Frontal(n) = measurePVS(pvs_mask_vol, frontal_mask, info.PixelDimensions);
        Parietal(n) = measurePVS(pvs_mask_vol, parietal_mask, info.PixelDimensions);
        Occipital(n) = measurePVS(pvs_mask_vol, occipital_mask, info.PixelDimensions);
        Temporal(n) = measurePVS(pvs_mask_vol, temporal_mask, info.PixelDimensions);
    end
    group_i0 = group_i0 + num_subjects(k);
end


T = table(subjectIDs, eTIV, vol_brainmask, ...
            [WM.Vol]', [WM.numPVS]', [WM.pvsVol]', [WM.pvsVolMean]', [WM.pvsVolMedian]', [WM.lengthMean]', [WM.lengthMedian]', [WM.widthMean]', [WM.widthMedian]', ...
            [CSO.Vol]', [CSO.numPVS]', [CSO.pvsVol]', [CSO.pvsVolMean]', [CSO.pvsVolMedian]', [CSO.lengthMean]', [CSO.lengthMedian]', [CSO.widthMean]', [CSO.widthMedian]', ...
            [Frontal.Vol]', [Frontal.numPVS]', [Frontal.pvsVol]', [Frontal.pvsVolMean]', [Frontal.pvsVolMedian]', [Frontal.lengthMean]', [Frontal.lengthMedian]', [Frontal.widthMean]', [Frontal.widthMedian]', ...
            [Parietal.Vol]', [Parietal.numPVS]', [Parietal.pvsVol]', [Parietal.pvsVolMean]', [Parietal.pvsVolMedian]', [Parietal.lengthMean]', [Parietal.lengthMedian]', [Parietal.widthMean]', [Parietal.widthMedian]', ...
            [Occipital.Vol]', [Occipital.numPVS]', [Occipital.pvsVol]', [Occipital.pvsVolMean]', [Occipital.pvsVolMedian]', [Occipital.lengthMean]', [Occipital.lengthMedian]', [Occipital.widthMean]', [Occipital.widthMedian]', ...
            [Temporal.Vol]', [Temporal.numPVS]', [Temporal.pvsVol]', [Temporal.pvsVolMean]', [Temporal.pvsVolMedian]', [Temporal.lengthMean]', [Temporal.lengthMedian]', [Temporal.widthMean]', [Temporal.widthMedian]');

writetable(T, 'PVS_stats_nnUNet_Jan31.xlsx', 'WriteMode', 'replacefile')

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
function [structure_stats] = measurePVS(pvs_vol, structure_mask, pixelDimensions)

structure_stats = struct('Vol', 0, 'numPVS', 0, 'pvsVol', 0, 'pvsVolMean', 0, 'pvsVolMedian', 0, ...
                         'lengthMean', 0, 'lengthMedian', 0, 'widthMean', 0, 'widthMedian', 0);

[stats, measure_all] = measurePVSstats(pvs_vol.*uint8(structure_mask), pixelDimensions);

if ~isempty(measure_all)
    structure_stats.Vol = nnz(structure_mask) * prod(pixelDimensions);
    
    structure_stats.numPVS = size(measure_all, 1);
    structure_stats.pvsVol = sum(measure_all(:, 3));

    structure_stats.lengthMean = stats(1);
    structure_stats.lengthMedian = stats(2);

    structure_stats.widthMean = stats(6);
    structure_stats.widthMedian = stats(7);

    structure_stats.pvsVolMean = stats(11);
    structure_stats.pvsVolMedian = stats(12);
end

end

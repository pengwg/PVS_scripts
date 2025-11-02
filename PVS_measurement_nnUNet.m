clear

addpath('matlab_auxiliary/')

data_path = {'/projects/2024-11_Perivascular_Space/PVS_B1_Analysis', ...
             '/projects/2024-11_Perivascular_Space/PVS_B2_Analysis', ...
             '/projects/2024-11_Perivascular_Space/PVS_B4_Analysis'};
num_subjects = [140, 54, 45];
batch_id_spec = {'PVS_%03d', 'PVS_2_%03d', 'PVS_4_%03d'};

p = gcp('nocreate');
if isempty(p)
   parpool(16);
end

PVS_measure_region('wm', data_path, num_subjects, batch_id_spec)
PVS_measure_region('cso', data_path, num_subjects, batch_id_spec)

return


function PVS_measure_region(region, data_path, num_subjects, batch_id_spec)

PVS_path = '/home/pw0032/Data/nnUNet_data/output_pvs';

total_num_subjects = sum(num_subjects);

stats = zeros(total_num_subjects, 15);
numPVS = zeros(total_num_subjects, 1);
pvsTotalVol = zeros(total_num_subjects, 1);
maskVol = zeros(total_num_subjects, 1);
eTIV = zeros(total_num_subjects, 1);
bgVol = zeros(total_num_subjects, 1);
wmVol = zeros(total_num_subjects, 1);

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

        disp(['Measure ' subject ' ' region '...' ])
		
        brain_fs = [FS_path '/' subject '/mri/brainmask.mgz'];
        brain_nii = [FS_path '/' subject '/mri/brainmask.nii.gz'];
        aseg_stats = [FS_path '/' subject '/stats/aseg.stats'];
        aseg_nii = [data_path_analysis '/' subject '/aseg_T2.nii.gz'];

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
        maskVol(n) = nnz(brain > 0) * prod(info.PixelDimensions);
        eTIV(n) = get_eTIV(aseg_stats);

        aseg_vol = niftiread(aseg_nii);
        wm_mask = ismember(aseg_vol, [2, 41]);
        wmVol(n) = nnz(wm_mask) * prod(info.PixelDimensions);

        info = niftiinfo(pvs_mask_file);
        pvs_mask_vol = niftiread(info);

        if strcmp(region, 'cso')
            cso_mask_vol = niftiread(fullfile(data_path_analysis, subject, 'cso_mask_T2.nii.gz'));
            pvs_mask_vol(~logical(cso_mask_vol)) = 0;
        end
        
        [stats_subject, measure_all] = measurePVSstats(pvs_mask_vol, info.PixelDimensions);

        stats(n, :) = stats_subject';
        numPVS(n) = size(measure_all, 1);

        if isempty(measure_all)
            disp(['No PVS detected in ' subject])
            continue
        end

        pvsLength = measure_all(:, 1);
        pvsWidth = measure_all(:, 2);
        pvsVolume = measure_all(:, 3);
        pvsTotalVol(n) = sum(pvsVolume);

        writetable(table(pvsLength, pvsWidth, pvsVolume), sprintf('%s/%s/PVS%d_%03d_%s_nnUNet.xlsx', data_path_analysis, subject, k, n, region), 'WriteMode', 'replacefile');
    end
    group_i0 = group_i0 + num_subjects(k);
end

lengthMean = stats(:, 1);
lengthMedian = stats(:, 2);
lengthStd = stats(:, 3);
lengthPrc25 = stats(:, 4);
lengthPrc75 = stats(:, 5);

widthMean = stats(:, 6);
widthMedian = stats(:, 7);
widthStd = stats(:, 8);
widthPrc25 = stats(:, 9);
widthPrc75 = stats(:, 10);

volMean = stats(:, 11);
volMedian = stats(:, 12);
volStd = stats(:, 13);
volPrc25 = stats(:, 14);
volPrc75 = stats(:, 15);

T = table(subjectIDs, eTIV, maskVol, bgVol, wmVol, pvsTotalVol, numPVS, ...
          lengthMean, lengthMedian, lengthStd, lengthPrc25, lengthPrc75, ...
          widthMean, widthMedian, widthStd, widthPrc25, widthPrc75, ...
          volMean, volMedian, volStd, volPrc25, volPrc75);

writetable(T, ['PVS_stats_' region, '_nnUNet.xlsx'], 'WriteMode', 'replacefile')

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



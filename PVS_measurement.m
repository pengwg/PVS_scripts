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

PVS_measure_region('wmbg', data_path, num_subjects, batch_id_spec)
PVS_measure_region('nawmbg', data_path, num_subjects, batch_id_spec)
PVS_measure_region('wm', data_path, num_subjects, batch_id_spec)
PVS_measure_region('nawm', data_path, num_subjects, batch_id_spec)
PVS_measure_region('bg', data_path, num_subjects, batch_id_spec)
PVS_measure_region('cso', data_path, num_subjects, batch_id_spec)
PVS_measure_region('nacso', data_path, num_subjects, batch_id_spec)

return


function PVS_measure_region(region, data_path, num_subjects, batch_id_spec)

total_num_subjects = sum(num_subjects);

stats = zeros(total_num_subjects, 15);
numPVS = zeros(total_num_subjects, 1);
pvsTotalVol = zeros(total_num_subjects, 1);
maskVol = zeros(total_num_subjects, 1);
eTIV = zeros(total_num_subjects, 1);
bgVol = zeros(total_num_subjects, 1);
wmVol = zeros(total_num_subjects, 1);
nawmVol = zeros(total_num_subjects, 1);
csoVol = zeros(total_num_subjects, 1);

pvsTotalVolGT100 = zeros(total_num_subjects, 1);
numPVSTotalVolGT100 = zeros(total_num_subjects, 1);

group_i0 = 0;
for k = 1 : length(num_subjects)
    PVS_path = [data_path{k} '/Frangi_pruned'];
    FS_path = [data_path{k} '/FS'];
    batch_id_spec_now = batch_id_spec{k};

    parfor n = group_i0 + 1 : group_i0 + num_subjects(k)
        subject = sprintf(batch_id_spec_now, n - group_i0);
        subjectIDs{n, 1} = subject;

        pvs_mask_file = sprintf(['%s/%s/' subject '_vsmask_%s.nii.gz'], PVS_path, subject, region);

        if exist(pvs_mask_file, 'file') ~= 2
            disp([pvs_mask_file ' not found!'])
            continue
        end

        disp(['Measure ' subject ' ' region '...' ])
		
        brain_fs = [FS_path '/' subject '/mri/brainmask.mgz'];
        brain_nii = [FS_path '/' subject '/mri/brainmask.nii.gz'];
        aseg_stats = [FS_path '/' subject '/stats/aseg.stats'];
        aseg_nii = [PVS_path '/' subject '/aseg_iso.nii.gz'];
        cso_nii = [PVS_path '/' subject '/cso_mask_iso.nii.gz'];

        if exist(brain_nii, 'file') ~= 2
            system(['mri_convert ' brain_fs ' ' brain_nii]);
        end

        info = niftiinfo(brain_nii);
        brain = niftiread(info);
        maskVol(n) = nnz(brain > 0) * prod(info.PixelDimensions);
        eTIV(n) = get_eTIV(aseg_stats);

        aseg_vol = niftiread(aseg_nii);
        bgVol(n) = nnz(ismember(aseg_vol, [11, 12, 13, 26, 50, 51, 52, 58])) * prod(info.PixelDimensions);

        info = niftiinfo([PVS_path '/' subject '/lst.nii.gz']);
        	wmh = niftiread(info);
    	    wm_mask = ismember(aseg_vol, [2, 41]);
        wmVol(n) = nnz(wm_mask) * prod(info.PixelDimensions);
        
        cso_mask = niftiread(cso_nii);
        csoVol(n) = nnz(wm_mask(logical(cso_mask))) * prod(info.PixelDimensions);
        
     	wm_mask(logical(wmh)) = 0;
        	nawmVol(n) = nnz(wm_mask) * prod(info.PixelDimensions);

        info = niftiinfo(pvs_mask_file);
        pvs_mask_vol = niftiread(info);

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

        pvsTotalVolGT100(n) = sum(pvsVolume(pvsVolume>100));
        numPVSTotalVolGT100(n) = sum(pvsVolume>100);

        writetable(table(pvsLength, pvsWidth, pvsVolume), sprintf('%s/%s/PVS%d_%03d_%s.xlsx', PVS_path, subject, k, n, region), 'WriteMode', 'replacefile');
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

T = table(subjectIDs, eTIV, maskVol, bgVol, wmVol, nawmVol, csoVol, pvsTotalVol, numPVS, pvsTotalVolGT100, numPVSTotalVolGT100, ...
          lengthMean, lengthMedian, lengthStd, lengthPrc25, lengthPrc75, ...
          widthMean, widthMedian, widthStd, widthPrc25, widthPrc75, ...
          volMean, volMedian, volStd, volPrc25, volPrc75);

writetable(T, ['PVS_stats_' region, '.xlsx'], 'WriteMode', 'replacefile')

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



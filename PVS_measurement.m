clear

addpath('matlab_auxiliary/')


data_path = '/projects/2024-11_Perivascular_Space/PVS_B4_Analysis';
% data_path = '/tm/Data/PVS';

PVS_path = [data_path '/Frangi_pruned'];
FS_path = [data_path '/FS'];
LST_path = [data_path '/LST'];

PVS_measure_region('wmbg', PVS_path, FS_path, LST_path)
PVS_measure_region('nawmbg', PVS_path, FS_path, LST_path)
PVS_measure_region('wm', PVS_path, FS_path, LST_path)
PVS_measure_region('nawm', PVS_path, FS_path, LST_path)
PVS_measure_region('bg', PVS_path, FS_path, LST_path)

return


function PVS_measure_region(region, PVS_path, FS_path, LST_path)

numSubjects = 45;

stats = zeros(numSubjects, 15);
number = zeros(numSubjects, 1);
pvsTotalVol = zeros(numSubjects, 1);
maskVol = zeros(numSubjects, 1);
eTIV = zeros(numSubjects, 1);
bgVol = zeros(numSubjects, 1);
wmVol = zeros(numSubjects, 1);
nawmVol = zeros(numSubjects, 1);

pvsTotalVolGT100 = zeros(numSubjects, 1);
numPVSTotalVolGT100 = zeros(numSubjects, 1);

p = gcp('nocreate');
if isempty(p)
    parpool(12);
end

parfor n = 1 : numSubjects
    subject = sprintf('PVS_4_%03d_vsmask_%s.nii.gz', n, region);
    pvs_mask_file = [PVS_path '/' subject];

    if exist(pvs_mask_file, 'file') ~= 2
        continue
    end

    disp(['Measure ' subject '...' ])

    brain_fs = sprintf('%s/PVS_4_%03d/mri/brainmask.mgz', FS_path, n);
    brain_nii = sprintf('%s/PVS_4_%03d/mri/brainmask.nii.gz', FS_path, n);
    aseg_fs = sprintf('%s/PVS_4_%03d/mri/aseg.mgz', FS_path, n);
    aseg_nii = sprintf('%s/PVS_4_%03d/mri/aseg.nii.gz', FS_path, n);
    aseg_stats = sprintf('%s/PVS_4_%03d/stats/aseg.stats', FS_path, n);
    % disp(brain_nii)
    
    if exist(brain_nii, 'file') ~= 2
        system(['mri_convert ' brain_fs ' ' brain_nii]);
    end

    if exist(aseg_nii, 'file') ~= 2
        system(['mri_convert ' aseg_fs ' ' aseg_nii]);
    end

    info = niftiinfo(brain_nii);
    brain = niftiread(info);
    maskVol(n) = nnz(brain > 0) * prod(info.PixelDimensions);
    eTIV(n) = get_eTIV(aseg_stats);

    aseg_vol = niftiread(aseg_nii);
    bgVol(n) = nnz(ismember(aseg_vol, [11, 12, 13, 26, 50, 51, 52, 58])) * prod(info.PixelDimensions);
    
	wmh = niftiread(sprintf('%s/PVS_4_%03d/space-flair_seg-lst.nii.gz', LST_path, n));
	wm_mask = ismember(aseg_vol, [2, 41]);
    wmVol(n) = nnz(wm_mask) * prod(info.PixelDimensions);
	wm_mask(logical(wmh)) = 0;
	nawmVol(n) = nnz(wm_mask) * prod(info.PixelDimensions);
	
    info = niftiinfo(pvs_mask_file);
    pvs_mask_vol = niftiread(info);
    
    [stats_subject, measure_all] = measurePVSstats(pvs_mask_vol, info.PixelDimensions);

    stats(n, :) = stats_subject';
    number(n) = size(measure_all, 1);
    
    if isempty(measure_all) 
        continue
    end

    length = measure_all(:, 1);
    width = measure_all(:, 2);
    volume = measure_all(:, 3);
    pvsTotalVol(n) = sum(volume);

    pvsTotalVolGT100(n) = sum(volume(volume>100));
    numPVSTotalVolGT100(n) = sum(volume>100);

    writetable(table(length, width, volume), sprintf('subjects_stats/PVS4_%03d_%s.xlsx', n, region));
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
subjectID = (1 : numSubjects)';

T = table(subjectID, eTIV, maskVol, bgVol, wmVol, nawmVol, pvsTotalVol, number, pvsTotalVolGT100, numPVSTotalVolGT100, ...
          lengthMean, lengthMedian, lengthStd, lengthPrc25, lengthPrc75, ...
          widthMean, widthMedian, widthStd, widthPrc25, widthPrc75, ...
          volMean, volMedian, volStd, volPrc25, volPrc75);

writetable(T, ['PVS4_stats_' region, '.xlsx'])

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



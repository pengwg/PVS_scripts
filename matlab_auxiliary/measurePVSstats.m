function [PVSstats,PVSall] = measurePVSstats(PVS3Darray,dim)
% This function calculates individual PVS metrics and calculate their stats (mean, median, etc)
%
% Input: 3D binary array that constitutes the binary PVS mask of any data type: e.g. integer, double, etc.
% 
% Outputs: Two column vectors: one with the stats of the individual PVS
% lengths, widths, sizes and shapes; and other with their cumulative values
%
% Example:[RightCSOPVS_stats(patientID,:),RightCSOPVSall] = measurePVSstats(RCSO_PVS); 
%
% Original code from LB <lucia.ballerini@ed.ac.uk>
%
% Adapted for anisotropic voxels by RDC <rduarte@ed.ac.uk>

 PVSlengthMean = 0;
 PVSlengthMedian = 0;
 PVSlengthStd = 0;
 PVSlengthPrc25 = 0;
 PVSlengthPrc75 = 0;
 PVSwidthMean = 0;
 PVSwidthMedian = 0;
 PVSwidthStd = 0;
 PVSwidthPrc25 = 0;
 PVSwidthPrc75 = 0;
 PVSsizeMean = 0; % Volume
 PVSsizeMedian = 0;
 PVSsizeStd = 0;
 PVSsizePrc25 = 0;
 PVSsizePrc75 = 0;

 PVSlength = []; % Cumulative values for plots
 PVSwidth = [];
 PVSsize = [];

 CC = bwconncomp(logical(PVS3Darray)); % Connected component analysis using default 26 dimensions (3D image)
 V = regionprops3(CC,"Volume");
 idx = find([V.Volume] > 1); % Look for PVS larger than a voxel
 L = labelmatrix(CC);
 LL = ismember(L,idx);
 CL = bwconncomp(LL);
 if ~isempty(CL.PixelIdxList) % Consider the possibility of no PVS at all in the ROI. Please mind that although it is in 3D it is not 'VoxelIdxList' but 'PixelIdxList'
     
        PVSstats3 = regionprops3(LL,"PrincipalAxisLength","BoundingBox","EigenVectors","Volume");
        if dim(1)~=dim(2) || dim(2)~=dim(3) || dim(1)~=dim(3)
            %PVSstats3 = anisotropic_correction(PVSstats3,dim);
            PVSstats3 = anisotropic_correction2(LL,PVSstats3,dim,2);
        else
            PVSstats3.PrincipalAxisLength=PVSstats3.PrincipalAxisLength.*dim(1);
            PVSstats3.Volume=PVSstats3.Volume.*prod(dim);
        end
        
        PVSlengthMean = mean(PVSstats3.PrincipalAxisLength(:,1));
        PVSlengthMedian = median(PVSstats3.PrincipalAxisLength(:,1));
        PVSlengthStd = std(PVSstats3.PrincipalAxisLength(:,1));
        PVSlengthPrc25 = prctile(PVSstats3.PrincipalAxisLength(:,1),25);
        PVSlengthPrc75 = prctile(PVSstats3.PrincipalAxisLength(:,1),75);

        PVSwidthMean = mean(PVSstats3.PrincipalAxisLength(:,2));
        PVSwidthMedian = median(PVSstats3.PrincipalAxisLength(:,2));
        PVSwidthStd = std(PVSstats3.PrincipalAxisLength(:,2));
        PVSwidthPrc25 = prctile(PVSstats3.PrincipalAxisLength(:,2),25);
        PVSwidthPrc75 = prctile(PVSstats3.PrincipalAxisLength(:,2),75);

        PVSlength = PVSstats3.PrincipalAxisLength(:,1); %cumulative for plots
        PVSwidth = PVSstats3.PrincipalAxisLength(:,2);

        %PVSstats3 = regionprops3(LL,"Volume");

        PVSsizeMean = mean(PVSstats3.Volume);
        PVSsizeMedian = median(PVSstats3.Volume);
        PVSsizeStd = std(PVSstats3.Volume);
        PVSsizePrc25 = prctile(PVSstats3.Volume,25);
        PVSsizePrc75 = prctile(PVSstats3.Volume,75);

        PVSsize = PVSstats3.Volume(:);
 end


 PVSstats=[
    PVSlengthMean;
    PVSlengthMedian;
    PVSlengthStd;
    PVSlengthPrc25;
    PVSlengthPrc75;

    PVSwidthMean;
    PVSwidthMedian;
    PVSwidthStd;
    PVSwidthPrc25;
    PVSwidthPrc75;

    PVSsizeMean;
    PVSsizeMedian;
    PVSsizeStd;
    PVSsizePrc25;
    PVSsizePrc75;
 ];


 PVSall=[PVSlength,PVSwidth,PVSsize]; % Changed to give a matrix of dimensions PVSnumber x 3 (MVH 03/02/2020)

end


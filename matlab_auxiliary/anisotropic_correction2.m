function stats_corrected=anisotropic_correction2(LL,stats,dim,precision)
% This function corrects the individual PVS measurements considering
% anistropic voxels
% LL is the label matrix of the PVS
% stats is a structure containing the following fields
%   BoundingBox is a matrix containting the boundig boxes of the PVS
% dim is a vector containting the voxel dimensions
% precision is an integer definin the times the scale is increased by 10 if
% there is no an exact isotropic conversion
%
% Written by anisotropic RDC <rduarte@ed.ac.uk>

    % Compute the scale each dimension needs to be multiplied in order to
    % be isotropic or approximate isotropic
    scale=dim/min(dim);
    a=1;
    while norm(scale-round(scale))>0 && a<precision
        scale=scale*10;
        a=a+1;
    end
    scale=round(scale);
    stats_corrected=stats;
    iso_size=dim./scale;
    sI=size(LL);
    % For each PVS
    for i=1:size(stats.BoundingBox,1)
        % Extract each bounding box from the PVS mask
        bbox=stats.BoundingBox(i,:);
        bbox=floor(bbox);
        bbox(bbox==0)=1;
        bbox(4:6)=bbox(4:6)+bbox(1:3)+1;
        if bbox(4)>sI(2)
            bbox(4)=sI(2);
        end
        if bbox(5)>sI(1)
            bbox(5)=sI(1);
        end
        if bbox(6)>sI(3)
            bbox(6)=sI(3);
        end
        tempI=LL(bbox(2):bbox(5),bbox(1):bbox(4),bbox(3):bbox(6));
        % Remove other clashing PVS
        tlabel=unique(tempI(tempI>0),'sorted');
        tempI(tempI==tlabel(end))=1;
        % Isotropic transformation
        tempI=imresize3(uint8(tempI),scale.*size(tempI),'nearest');
        % Measure Number of PVS voxels and Principal Axis Lengths
        PVSstats3 = regionprops3(logical(tempI),"PrincipalAxisLength","Volume");
        stats_corrected.PrincipalAxisLength(i,:)=PVSstats3.PrincipalAxisLength(1,:)*iso_size(1);
        % Convert voxels to volume
        stats_corrected.Volume(i,:)=PVSstats3.Volume(1,:)*prod(iso_size);
    end
end
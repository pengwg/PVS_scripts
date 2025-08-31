function ff=prunePVS(VSL,I)
    SE = strel('sphere',2);
    dVSL=imdilate(VSL,SE);
    dI=I(dVSL>0);
    if ~isempty(dI)
        [idx,c] = kmeans(dI,2,'MaxIter',10000,'Replicates',5);
        oVSL=VSL;
        if c(1)>c(2)
            VSL(dVSL>0)=(idx==1)&(dI>(c(2)+(c(1)-c(2))*2/3));
        else
            VSL(dVSL>0)=(idx==2)&(dI>(c(1)+(c(2)-c(1))*2/3));
        end
        ff=VSL.*oVSL;
    else
        ff=VSL;
    end
end
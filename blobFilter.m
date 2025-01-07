function outputImage = blobFilter(BW1, blobfilter_sigma)    
    % Get connected components
    CC = bwconncomp(BW1);
    S  = regionprops(CC,'Area');

    % Normal distribution fit
    [mu_hessian, sigma_hessian] = normfit(cell2mat(struct2cell(S)));

    % check for sigma
    if ((isempty(sigma_hessian)) || (isnan (sigma_hessian)))
        sigma_hessian = 0;
    end

    % Remove smaller area lesser than sigma_morph
    outputImage = bwareaopen(BW1, ceil(blobfilter_sigma * ...
                                sigma_hessian), 8);
end
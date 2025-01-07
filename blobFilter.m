function outputImage = blobFilter(BW1, blobfilter_sigma)  
%%***********************************************************************%
%*                            BLob filter                               *%
%*                    Removes noisy blobs/artifacts                     *%
%*                                                                      *%
%* Code author: Preetham Manjunatha                                     *%
%* Github link: https://github.com/preethamam                           %*
%* Date: 01/7/2025                                                     *%
%************************************************************************%
%
%************************************************************************%
%
% Usage: outputImage = blobFilter(BW1, blobfilter_sigma)
% Inputs: BW1  - Input binary image
%         blobfilter_sigma - blobs filter standard deviation
% 
% Outputs: outputImage - output image
%
%
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
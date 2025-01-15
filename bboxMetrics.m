function [TruePositiveBbox, FalsePositiveBbox, FalseNegativeBbox, RGB] = bboxMetrics...
    (input, Ioriginal, Iground2PrecisionRecall, blobFilteredImage)
%%***********************************************************************%
%*                     Binary class bounding box metrics                *%
%*        Finds the true, false positives and  false negatives.         *%
%*                                                                      *%
%* Code author: Preetham Manjunatha                                     *%
%* Github link: https://github.com/preethamam                           *%
%* Date: 01/7/2025                                                      *%
%************************************************************************%
%
%************************************************************************%
%
% Usage: [TruePositiveBbox, FalsePositiveBbox, FalseNegativeBbox] = bboxMetrics...
%                       (input, imnum, Ioriginal, Igrayscale, Iground2PrecisionRecall, 
%                       segmentedImage, blobFilteredImage, ImageID)
%
% Inputs: input  - Ground-truth image
%         Ioriginal - Original RGB image
%         Iground2PrecisionRecall - Groundtruth image
%         blobFilteredImage - Blob filtered image
%
% Outputs: TruePositiveBbox - True positive bounding boxes count
%          FalsePositiveBbox - False positive bounding boxes count
%          FalseNegativeBbox - False negative bounding boxes count
%

% Ground-truth BBox
CCIground = bwconncomp(Iground2PrecisionRecall);
statsIground = regionprops(CCIground,'Area','BoundingBox');

% Classifier output BBox
CCIclassifier = bwconncomp(blobFilteredImage);
statsIclassifier = regionprops(CCIclassifier,'Area','BoundingBox');

% Count initialization
tpCount = 0;
fpCount = 0;
fnCount = 0;

Ioriginal_dup = Ioriginal;

% BBox image holder
RGB = [];

if~(isempty(statsIground))
    gtarray = zeros(length(statsIground),1);
    for i = 1:length(statsIclassifier)
        bboxA = statsIclassifier(i).BoundingBox;
        maxIOUIndex = -1;
        maxIOU = -1;
        % Groud-truth BBox (green color)
        if (strcmp(input.figShow_TPFPFN,'yes'))
            RGB = insertShape(Ioriginal_dup,"rectangle",bboxA,'Color','yellow',...
                                'Opacity', 0.6, 'LineWidth', 1);
        end
                        
        for j = 1:length(statsIground)                  
            bboxB = statsIground(j).BoundingBox;
            overlapRatio = bboxOverlapRatio(bboxA,bboxB);
            if (overlapRatio > maxIOU)
                maxIOUIndex = j;
                maxIOU = overlapRatio;
            end

            % Algorithm output BBox (yellow color)
            if (strcmp(input.figShow_TPFPFN,'yes'))
                RGB = insertShape(RGB,"rectangle",bboxB,...
                    'Color','green','Opacity', 0.6, 'LineWidth', 1);
            end
        end
        
        if maxIOU < input.BBoxthreshold || maxIOUIndex == -1
            fpCount = fpCount + 1;
        elseif gtarray(maxIOUIndex) == 0
            gtarray(maxIOUIndex) = maxIOU;
            tpCount = tpCount + 1;
        elseif maxIOU > gtarray(maxIOUIndex)
            gtarray(maxIOUIndex) = maxIOU;
            fpCount = fpCount + 1;
        else
            fpCount = fpCount + 1;
        end
        Ioriginal_dup = RGB;
    end
    fnCount = length(statsIground) - tpCount;
   
else
    if~(isempty(statsIclassifier))
        % Find flase postive BBox to display
        bboxA = statsIclassifier(1).BoundingBox;
    else
        bboxA = [];
    end
        
    % Groud-truth BBox (green color)
    if (strcmp(input.figShow_TPFPFN,'yes'))
        RGB = insertShape(Ioriginal_dup,'rectangle',bboxA,'Color','yellow',...
                            'Opacity', 0.0, 'LineWidth', 1);
    end
    for j = 1:length(statsIclassifier)
        fpCount = fpCount + 1;

        % Find flase postive BBox to display
        bboxB = statsIclassifier(j).BoundingBox;

        % Algorithm output BBox (yellow color)
        if (strcmp(input.figShow_TPFPFN,'yes'))
            RGB = insertShape(RGB,'rectangle',bboxB,...
                'Color','yellow','Opacity', 0.6, 'LineWidth', 1);
        end
    end
end

% Calculate the TP, FP and FN Bounding box hits
TruePositiveBbox  = tpCount;

FalsePositiveBbox = fpCount;

FalseNegativeBbox = fnCount;
end


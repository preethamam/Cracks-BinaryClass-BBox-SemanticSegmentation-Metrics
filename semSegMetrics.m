function [ TruePositivePix, FalsePositivePix, FalseNegativePix, TrueNegativePix  ] = semSegMetrics(Iground2PrecisionRecall,...
                                    classifierImage)

%%***********************************************************************%
%*                     Semantic segmentation metrics                    *%
%*        Finds the true, false positives and true, false negatives.    *%
%*                                                                      *%
%* Code author: Preetham Manjunatha                                     *%
%* Github link: https://github.com/preethamam                           %*
%* Date: 01/7/2025                                                     *%
%************************************************************************%
%
%************************************************************************%
%
% Usage: metrics  = [ TruePositivePix, FalsePositivePix, FalseNegativePix, 
% TrueNegativePix  ] = semSegMetrics(Iground2PrecisionRecall, classifierImage)
%
% Inputs: Iground2PrecisionRecall  - Ground-truth image
%         classifierImage - Predicted image
%
% Outputs: TruePositivePix - True positive pixels count
%          FalsePositivePix - False positive pixels count
%          FalseNegativePix - False negative pixels count
%          TrueNegativePix - True negative pixels count
%

% True positive
TP = bitand(Iground2PrecisionRecall, classifierImage);

% False positive
FP = imsubtract(classifierImage,TP);
FP(FP == -1)  = 1;

% False negative
FN = imsubtract(Iground2PrecisionRecall,TP);
FN(FN == -1)  = 1;

% True negative
TN = ~(Iground2PrecisionRecall | classifierImage);

% Calculate the TP, FP and FN pixels
TruePositivePix  = sum(sum(TP));

FalsePositivePix = sum(sum(FP));

FalseNegativePix = sum(sum(FN));

TrueNegativePix  = sum(sum(TN));

end


%% Start parameters
%--------------------------------------------------------------------------
clear; close all; clc;
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);
Start = tic;

%% Inputs
%--------------------------------------------------------------------------
% Metrics and image show parameters
%--------------------------------------------------------------------------
input.BBoxthreshold = 0.5;
input.figShow_TPFPFN = 'yes';   % 'yes' | 'no'
input.classifierName = 'Blob Filter';

%--------------------------------------------------------------------------
% Blob filtering
%--------------------------------------------------------------------------
blobFilterSigma = 0.5;

%--------------------------------------------------------------------------
% Multiscale fractional anisotropic tensor options/Inputs
%--------------------------------------------------------------------------
MFAT_TYPE = 'ProbabilisticFAT';   % 'EigenFAT' | 'ProbabilisticFAT'

% MFAT filter options
MFAToptions.sigmas1       = 0.7181;  % 1
MFAToptions.sigmas2       = 5; % 12.5
MFAToptions.sigmasScaleRatio = 0.25;
MFAToptions.spacing       = 0.39; %0.4, 0.45 0.39
MFAToptions.tau           = 0.25; 
MFAToptions.tau2          = 0.5; 
MFAToptions.D             = 0.5; %0.85
MFAToptions.whiteondark   = false;

%% Input images
images = dir('images');
imFiles = images(~ismember({images.name},{'.','..'}));

labels = dir('labels');
labelsimFiles = labels(~ismember({labels.name},{'.','..'}));

%% Folders I/O
addpath('mfat')

%% Process images
TPFPFNBboxMFAT      = zeros(length(imFiles), 3);
TPFPFNSemSegMFAT    = zeros(length(imFiles), 4);

for i = 1:length(imFiles)
    
    % Image filepath
    imageID = fullfile(imFiles(i).folder, imFiles(i).name);

    % Image read
    inputImage = imread(imageID);    

    % Labels
    labels = imread(fullfile(labelsimFiles(i).folder, labelsimFiles(i).name));
    labels = imbinarize(rgb2gray(labels));

    % Convert to grayscale
    imageGray = rgb2gray(inputImage);
    imageGrayDbl = double(rgb2gray(inputImage));

    % MFAT crack detection            
    switch MFAT_TYPE
        case 'EigenFAT'
            % Proposed Method (Eign values based version)
            Ivessel = FractionalIstropicTensor(imageGrayDbl, MFAToptions);
            Ivessel = normalize(Ivessel);
        case 'ProbabilisticFAT'
            % Proposed Method (probability based version)
            % Ivessel = ProbabiliticMFATSpacing(imageGray, MFAToptions);
            Ivessel = ProbabiliticMFATSigmas(imageGrayDbl, MFAToptions);
            Ivessel = normalize(Ivessel);
    end
    
    % Binarize the image
    mfatOutputImage = imbinarize(Ivessel, graythresh(Ivessel));
    
    % Blob filtering
    blobFilterImage = blobFilter(mfatOutputImage, blobFilterSigma);  
    
    % Bounding box metrics collection
    [tpBbox, fpBbox, fnBbox] = bboxMetrics(input, i, inputImage, imageGray, labels, ...
        mfatOutputImage, blobFilterImage, imageID);
    TPFPFNBboxMFAT(i,:) = [tpBbox, fpBbox, fnBbox];
    
    % Semantic segmentation metrics collection
    [tpSSeg, fpSSeg, fnSSeg, tnSSeg] = semSegMetrics(labels, blobFilterImage);
    TPFPFNSemSegMFAT(i,:) = [tpSSeg, fpSSeg, fnSSeg, tnSSeg];
end


%% Precision and recall values for bounding box
TPFPFNBbox = sum(TPFPFNBboxMFAT);
PrecisionBBox   = TPFPFNBbox(1) / (TPFPFNBbox(1) + TPFPFNBbox(2));
RecallBBox      = TPFPFNBbox(1) / (TPFPFNBbox(1) + TPFPFNBbox(3));
F1scoreBBox     = 2*((PrecisionBBox * RecallBBox)/(PrecisionBBox + RecallBBox));

BBoxMetrics.precision = PrecisionBBox;
BBoxMetrics.recall = RecallBBox;
BBoxMetrics.F1score = F1scoreBBox;

%% Semantic segmentation metrics
TPFPFNTNSemSegMFATTotal = sum(TPFPFNSemSegMFAT);
confmatANNPix = [TPFPFNTNSemSegMFATTotal(1), TPFPFNTNSemSegMFATTotal(3); 
                 TPFPFNTNSemSegMFATTotal(2), TPFPFNTNSemSegMFATTotal(4)];
semSegMetrics = multiclassPrecisionRecall(confmatANNPix);

%% End parameters
%--------------------------------------------------------------------------
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);
statusFclose = fclose('all');
if(statusFclose == 0)
    disp('All files are closed.')
end
Runtime = toc(Start);
disp(Runtime);





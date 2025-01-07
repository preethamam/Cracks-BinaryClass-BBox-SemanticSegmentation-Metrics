function [ TruePositiveBbox, FalsePositiveBbox, FalseNegativeBbox] = bboxMetrics...
    (input, imnum, Ioriginal, Igrayscale, Iground2PrecisionRecall, Imfat, blobFilteredImage, ...
    ImageID)
  
% Ground-truth BBox
CCIground = bwconncomp(Iground2PrecisionRecall);
statsIground = regionprops(CCIground,'Area','BoundingBox');

% Classifier output BBox
CCIclassifier = bwconncomp(blobFilteredImage);
statsIclassifier = regionprops(CCIclassifier,'Area','BoundingBox');


% True positive
TP = bitand(Iground2PrecisionRecall, blobFilteredImage);

% False positive
FP = imsubtract(blobFilteredImage,TP);
FP(FP == -1)  = 1;

% False negative
FN = imsubtract(Iground2PrecisionRecall,TP);
FN(FN == -1)  = 1;

% Count initialization
tpCount = 0;
fpCount = 0;
fnCount = 0;

Ioriginal_dup = Ioriginal;

% Extract file parts
[pathstr,filename,ext] = fileparts(ImageID); %#ok<ASGLU>

% BBox image holder
RGB = [];

% Find TP/FP/FN counts and plot the bounding boxes
if (strcmp(input.figShow_TPFPFN,'yes'))
    fh = figure(1);    
    fh.WindowState = 'maximized';
    tiledlayout(4, 3, TileSpacing="tight", Padding="tight");
    hold on
end

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


% Plot the output and save them if needed
if (strcmp(input.figShow_TPFPFN,'yes'))
    hold off
    
    % Row 1
    ax1 = nexttile; imshow(Ioriginal); title('Original', 'fontsize', 25)   
    ax2 = nexttile; imshow(Igrayscale); title('Grayscale', 'fontsize', 25)
    ax3 = nexttile; imshow(Iground2PrecisionRecall); title('Ground-truth', 'fontsize', 25)
   

    % Row 2
    % Overlay 
    BW_overlay_classifier = imoverlay(Imfat, blobFilteredImage, [1 1 0]);
    ax4 = nexttile; imshow(Imfat); title('MFAT', 'fontsize', 25)
    ax5 = nexttile; imshow(blobFilteredImage); title('Blob Filtered Output', 'fontsize', 25)
    ax6 = nexttile; imshow(BW_overlay_classifier); title('Blob/filt. Overlay', 'fontsize', 25);

    % Row 3
    TP_overlay = imoverlay(Ioriginal, TP, [1 0 0]);
    ax7 = nexttile; imshow(TP_overlay);  title('TP pixels', 'fontsize', 25);

    FP_overlay = imoverlay(Ioriginal, FP, [0 1 0]);
    ax8 = nexttile; imshow(FP_overlay); title('FP pixels', 'fontsize', 25)

    FN_overlay = imoverlay(Ioriginal, FN, [0 0 1]);
    ax9 = nexttile; imshow(FN_overlay); title('FN pixels', 'fontsize', 25);

    % Row 4
    if (isempty(RGB))
        ax10 = nexttile; imshow([]);
    else
        ax10 = nexttile; imshow(RGB); title('Bounding Boxes', 'fontsize', 25)
    end
    
    ax11 = nexttile; imshow(Ioriginal); hold on;
    h = imshow(Iground2PrecisionRecall); title('Ground-truth Quality', 'fontsize', 25);
    set(h, 'AlphaData', 0.4); % .5 transparency
    
    % Overall TPFPFN pixels
    TP_red = imoverlay(Iground2PrecisionRecall, TP, [1 0 0]);
    FP_green = imoverlay(TP_red, FP, [0 1 0]);
    FN_blue = imoverlay(FP_green, FN, [0 0 1]);
    
    ax12 = nexttile; imshow(Ioriginal); hold on;
    h1 = imshow(FN_blue); title('Overall Pixels (TPFPFN)', 'fontsize', 25);
    set(h1, 'AlphaData', 0.35); % .5 transparency
    stitle = sgtitle(['Image No.: ' num2str(imnum) ' | ', 'File Name: ' filename, ' | ' input.classifierName]);
    set(stitle, 'Interpreter', 'none')

    % Link axes
    linkaxes([ax1,ax2,ax3,ax4,ax5,ax6,ax7,ax8,ax9,ax10,ax10,ax11,ax12],'xy')
    
    drawnow;
    
    % Save the images
    exportgraphics(fh, 'crack_bboxes_tpfpfntn_pixels.png')
end


% Calculate the TP, FP and FN Bounding box hits
TruePositiveBbox  = tpCount;

FalsePositiveBbox = fpCount;

FalseNegativeBbox = fnCount;

end


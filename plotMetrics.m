function plotMetrics(input, imnum, Ioriginal, Igrayscale, Iground2PrecisionRecall, segmentedImage, blobFilteredImage, ...
    imageID, rgbBboxOverlay)

    % True positive
    TP = bitand(Iground2PrecisionRecall, blobFilteredImage);
    
    % False positive
    FP = imsubtract(blobFilteredImage,TP);
    FP(FP == -1)  = 1;
    
    % False negative
    FN = imsubtract(Iground2PrecisionRecall,TP);
    FN(FN == -1)  = 1;
    
    % Find TP/FP/FN counts and plot the bounding boxes
    if (strcmp(input.figShow_TPFPFN,'yes'))
        fh = figure(1);    
        fh.WindowState = 'maximized';
        tiledlayout(4, 3, TileSpacing="tight", Padding="tight");
        hold on
    end

    % Extract file parts
    [pathstr,filename,ext] = fileparts(imageID); %#ok<ASGLU>
    
    % Plot the output and save them if needed
    if (strcmp(input.figShow_TPFPFN,'yes'))
        hold off
        
        % Row 1
        ax1 = nexttile; imshow(Ioriginal); title('Original', 'fontsize', 25)   
        ax2 = nexttile; imshow(Igrayscale); title('Grayscale', 'fontsize', 25)
        ax3 = nexttile; imshow(Iground2PrecisionRecall); title('Ground-truth', 'fontsize', 25)
       
    
        % Row 2
        % Overlay 
        BW_overlay_classifier = imoverlay(segmentedImage, blobFilteredImage, [1 1 0]);
        ax4 = nexttile; imshow(segmentedImage); title('MFAT', 'fontsize', 25)
        ax5 = nexttile; imshow(blobFilteredImage); title('Blob Filtered Output', 'fontsize', 25)
        ax6 = nexttile; imshow(BW_overlay_classifier); title('Blob/filt. Overlay', 'fontsize', 25);
    
        % Row 3
        TP_overlay = imoverlay(Ioriginal, TP, [0 1 0]);
        ax7 = nexttile; imshow(TP_overlay);  title('TP Pixels', 'fontsize', 25);
    
        FP_overlay = imoverlay(Ioriginal, FP, [1 0 0]);
        ax8 = nexttile; imshow(FP_overlay); title('FP Pixels', 'fontsize', 25)
    
        FN_overlay = imoverlay(Ioriginal, FN, [0 0 1]);
        ax9 = nexttile; imshow(FN_overlay); title('FN Pixels', 'fontsize', 25);
    
        % Row 4
        if (isempty(rgbBboxOverlay))
            ax10 = nexttile; imshow([]);
        else
            ax10 = nexttile; imshow(rgbBboxOverlay); title('Bounding Boxes', 'fontsize', 25)
        end
        
        qualityOverlay = imoverlay(Iground2PrecisionRecall, Iground2PrecisionRecall, [0 1 0]);
        ax11 = nexttile;         
        h1 = imshow(Ioriginal); hold on;
        h2 = imshow(qualityOverlay); 
        title('Ground-truth Quality', 'fontsize', 25);
        set(h1, 'AlphaData', 1); % .5 transparency
        set(h2, 'AlphaData', 0.4); % .5 transparency
        
        % Overall TPFPFN pixels
        TP_red = imoverlay(Ioriginal, TP, [0 1 0]);
        FP_green = imoverlay(TP_red, FP, [1 0 0]);
        FN_blue = imoverlay(FP_green, FN, [0 0 1]);
        
        ax12 = nexttile; 
        imshow(FN_blue); title('Overall Pixels (TPFPFN)', 'fontsize', 25);
        stitle = sgtitle(['Image No.: ' num2str(imnum) ' | ', 'File Name: ' filename, ' | ' input.classifierName]);
        set(stitle, 'Interpreter', 'none')
    
        % Link axes
        linkaxes([ax1,ax2,ax3,ax4,ax5,ax6,ax7,ax8,ax9,ax10,ax10,ax11,ax12],'xy')
        
        drawnow;
        
        % Save the images
        exportgraphics(fh, 'crack_bboxes_tpfpfntn_pixels.png')
    end
end
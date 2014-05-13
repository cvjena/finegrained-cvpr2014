function fgImages_cropAndStore( settings )

    % set default values
    
    if ( nargin < 1 )
        settings = [];
    end
    
    if ( ~isfield(settings, 'd_enlargeBox') || isempty ( settings.d_enlargeBox ) )
        d_enlargeBox = 0.1;
    else
        d_enlargeBox = settings.d_enlargeBox;
    end
    
    if ( ~isfield(settings, 'i_nrClasses') || isempty ( settings.i_nrClasses ) )
        i_nrClasses = 200;
    else
        i_nrClasses = settings.i_nrClasses;
    end
    
    if ( ~isfield(settings, 's_dataset') || isempty ( settings.s_dataset ) )
        s_dataset = 'cub200_2011';
    else
        s_dataset = settings.s_dataset;
    end
    
    if ( ~isfield(settings, 's_destination') || isempty ( settings.s_destination ) )
        s_destination = sprintf('%s%s/cropped/',[getenv('HOME') '/data/finegrained/'],s_dataset);
    else
        s_destination = settings.s_destination;
    end
    
    if ( ~isfield(settings, 'b_showCroppedImages') || isempty ( settings.b_showCroppedImages ) )
        b_showCroppedImages = false;
    else
        b_showCroppedImages = settings.b_showCroppedImages;
    end
    
        

    % get image filenames
    [imagesTrain, labelsTrain, imagesTest, labelsTest ] = getDataset(s_dataset,'imagenames',i_nrClasses);
    
%     % get image bounding boxes
%     [images_train, labels_train, images_test, ~ ] = getDataset(dataset,'bboxes',i_nrClasses);
    
    
    classes = unique ( labelsTrain );
    
    % loop over images of same category, crop them to their bounding boxes,
    % and store them in specified folder
    
    config.b_cropToBoundingbox = true;
    
    config.b_resizeImages = false;
    config.i_xsize= 256;
    config.i_ysize = 256;
    

    
    for i_classCnt = 1:length( classes )
        
        % get index of current class
        i_classIdx = classes ( i_classCnt );
        
        % get images of current class
        imagesOfClass = imagesTrain ( labelsTrain == i_classIdx );
        
        if ( isempty( imagesOfClass ) )
            s_info = sprintf ( 'No images for class %d available!', i_classIdx);
            disp ( s_info )
            continue;
        end
        
        %%%%% DETERMINE CLASS NAME
        idx = strfind ( imagesOfClass{1}, '/' );
        idx = idx(:, (size(idx,2)-1):size(idx,2) );
        s_classname = imagesOfClass{1}(idx(1):idx(2));        
        
        s_destinationForClass = sprintf( '%s%s', s_destination, s_classname );
        
        % create output directory for class if not existing
        if (  exist ( s_destinationForClass, 'dir' ) == 0 )
            mkdir ( s_destinationForClass );
        end
        
        for i_imgIdx=1:length(imagesOfClass)     
            
            % read image
            img = imread( imagesOfClass{i_imgIdx} );
            i_imgHeight = size(img,1);
            i_imgWidth  = size(img,2);
            
            % get bounding box
            bbox = readBbox( imagesOfClass{i_imgIdx}, config);
            
            % enlarge bounding box by given factor
            i_bbWidth = bbox.right-bbox.left;
            i_bbHeight = bbox.bottom-bbox.top;
            
            bboxEnlarged.left    = max ( 0,        round( bbox.left   - i_bbWidth *d_enlargeBox/2.0 ) );
            bboxEnlarged.right   = min ( i_imgWidth,  round( bbox.right  + i_bbWidth *d_enlargeBox/2.0 ) );
            bboxEnlarged.top     = max ( 0,        round( bbox.top    - i_bbHeight*d_enlargeBox/2.0 ) );
            bboxEnlarged.bottom  = min ( i_imgHeight, round( bbox.bottom + i_bbHeight*d_enlargeBox/2.0 ) );


            % crop image accordingly
            if isfield(config,'b_cropToBoundingbox') && config.b_cropToBoundingbox
                imgCropped = imcrop(img, [bboxEnlarged.left bboxEnlarged.top bboxEnlarged.right-bboxEnlarged.left bboxEnlarged.bottom-bboxEnlarged.top ]);
            end 
            
            if isfield(config,'b_resizeImages') && config.b_resizeImages
                % do some resize operation here
                % currently, we perform this step using external
                % image magic commands...
            end
            
            if ( b_showCroppedImages ) 
                figure;
                imshow ( img );        
                figure;
                imshow ( imgCropped ); 
                
                pause
                close all;
            end
            
            %%%% save results
            
            % determine image name
            idx = strfind ( imagesOfClass{i_imgIdx}, '/' );
            idx = idx(:, (size(idx,2)-1):size(idx,2) );
            s_filename = imagesOfClass{i_imgIdx}(idx(2):length(imagesOfClass{i_imgIdx}));        

            s_destinationForFile = sprintf( '%s%s', s_destinationForClass, s_filename );            

            imwrite ( imgCropped, s_destinationForFile );
        end        
    end
    


    
    

    
end
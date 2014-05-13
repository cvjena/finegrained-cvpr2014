function fgImages_crop_adaptBoundingBoxAndPartAnnotations( settings )

    % set default values
    
    if ( nargin < 1 )
        settings = [];
    end
    
    if ( ~isfield(settings, 'd_enlargeBox') || isempty ( settings.d_enlargeBox ) )
        d_enlargeBox = 0.1;
    else
        d_enlargeBox = settings.d_enlargeBox;
    end
    
    
    if ( ~isfield(settings, 's_dataset') || isempty ( settings.s_dataset ) )
        s_dataset = 'cub200_2011';
    else
        s_dataset = settings.s_dataset;
    end
    
    if ( ~isfield(settings, 's_location') || isempty ( settings.s_location ) )
        s_location = '/home/dbv/bilder/FineGrained/CUB_200_2011';
    else
        s_location = settings.s_location;
    end
    
    if ( ~isfield(settings, 's_cacheWidthAndHeight') || isempty ( settings.s_cacheWidthAndHeight ) )
        s_cacheWidthAndHeight = sprintf('%s/widthAndHeight_finegrained.mat',s_location);
    else
        s_cacheWidthAndHeight = settings.s_cacheWidthAndHeight;
    end
    
    if ( ~isfield(settings, 's_destinationBoundinBoxes') || isempty ( settings.s_destinationBoundinBoxes ) )
        s_destinationBoundinBoxes = 'bounding_boxes.txt';
    else
        s_destinationBoundinBoxes = settings.s_destinationBoundinBoxes;
    end
    
    if ( ~isfield(settings, 's_destinationParts') || isempty ( settings.s_destinationParts ) )
        s_destinationParts = 'part_locs.txt';
    else
        s_destinationParts = settings.s_destinationParts;
    end    
    
    
    
    
    config.i_xsize= 256;
    config.i_ysize = 256;    

    %% obtain width and height for every image  
    
    try
        sizes = load( s_cacheWidthAndHeight );
        i_imgWidth = sizes.i_imgWidth;
        i_imgHeight = sizes.i_imgHeight;
    catch
        disp ('error while loading cache image sizes - reload them from image data')
        
        fid = fopen([ s_location '/images.txt' ]);
        images = textscan(fid, '%s %s');
        fclose(fid);
        images = images{2};

        images = strcat([s_location '/images/'],images);          
        
        i_imgWidth = zeros(size(images,1),1);
        i_imgHeight = zeros(size(images,1),1);

        for i_imgIdx=1:size(images,1)
            img = imread( images{i_imgIdx} );
            i_imgWidth(i_imgIdx) = size(img,2);
            i_imgHeight(i_imgIdx)  = size(img,1);
            clear('img');
        end
        
        clear ('images');        
    end

    
    %% adaptation of bounding box information
    
    % read bounding box information for every image
    % coding: <imgID left top width height>
    bboxes = load([ s_location '/bounding_boxes.txt' ]);
    
    i_bbLeft = bboxes(:,2);
    i_bbTop = bboxes(:,3);
    i_bbWidth = bboxes(:,4);
    i_bbHeight = bboxes(:,5);    
    
    bbTransformed = zeros(size(bboxes,1),4,'int16');  
    
    % compute adapted bounding box to which we cropped the images
    i_bbEnlargedLeft    = max ( 0,          round( i_bbLeft   - i_bbWidth *d_enlargeBox/2.0 ) );
    i_bbEnlargedRight   = min ( i_imgWidth,  round( i_bbLeft + i_bbWidth + i_bbWidth *d_enlargeBox/2.0 ) );
    i_bbEnlargedTop     = max ( 0,          round( i_bbTop    - i_bbHeight*d_enlargeBox/2.0 ) );
    i_bbEnlargedBottom  = min ( i_imgHeight, round( i_bbTop + i_bbHeight + i_bbHeight*d_enlargeBox/2.0 ) );

    i_bbEnlargedWidth   = i_bbEnlargedRight - i_bbEnlargedLeft;
    i_bbEnlargedHeight  = i_bbEnlargedBottom - i_bbEnlargedTop;  
    

    d_scaleWidth = double(config.i_xsize)./i_bbEnlargedWidth;
    d_scaleHeight = double(config.i_ysize)./i_bbEnlargedHeight;   
    
    % transform bounding boxes
    bbTransformed(:,1) = round( (i_bbLeft - i_bbEnlargedLeft) .* d_scaleWidth ); %left
    bbTransformed(:,2) = round( (i_bbTop - i_bbEnlargedTop) .* d_scaleHeight ); %top
    bbTransformed(:,3) = round( i_bbWidth .* d_scaleWidth ); %width
    bbTransformed(:,4) = round( i_bbHeight .* d_scaleHeight ); %height
    
    % save adapted bounding boxes
    fileID_bb = fopen(s_destinationBoundinBoxes,'w');
    fprintf(fileID_bb,'%d %.1f %.1f %.1f %.1f \n',[ (1:size(bboxes,1))' , bbTransformed]' );
    fclose(fileID_bb);
    
    %% adaptation of part centers
    
    % read part centers for every image
    % coding: <imgID partID centerX centerY visible>
    parts = load([ s_location '/parts/part_locs.txt' ]); 
    
    partsTransformed = zeros(size(parts,1),2);  
    
    partsTransformed(:,1) = round( (parts(:,3) - i_bbEnlargedLeft(parts(:,1)) ).* d_scaleWidth(parts(:,1)) ); % center in x-direction
    partsTransformed(:,2) = round( (parts(:,4) - i_bbEnlargedTop(parts(:,1)) ) .* d_scaleHeight(parts(:,1)) ); % center in y-direction
    
    % parts not visible have positions equal to 0
    % all visible parts have centers always located within the bounding
    % box, so nothing harmful can happen here
    partsTransformed = max(0, partsTransformed);
    
    % save adapted part centers
    fileID_bb = fopen(s_destinationParts,'w');
    fprintf(fileID_bb,'%d %d %.1f %.1f %d \n',[ parts(:,1:2), partsTransformed, parts(:,5)]' );
    fclose(fileID_bb);    
    
    end

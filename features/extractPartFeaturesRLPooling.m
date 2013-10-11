function [ part_features ] = extractPartFeaturesRLPooling( images_train, parts_train, labels_train, images_test, parts_test, config, vocabs)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    part_names = {'back    ' 'beak    ' 'belly    ' 'breast    ' 'crown    ' 'forehead' 'left eye' 'left leg' 'left wing' 'nape    ' 'right eye' 'right leg' 'right wing' 'tail    ' 'throat    '};

	parts = [];
    for pi = [1 2 3 4 5 6 10 14 15]
        parts(end+1).name = [ part_names{pi} ' (' config.featureExtractFun ')'];
        fprintf('compute features for single part %d (%s)\n',pi,parts(end).name);

        config = prepareConfigForParts(images_train, parts_train, pi, config);
        if isempty(vocabs)
            [vocabulary] = vlfeatCreateCodebookAib(images_train, labels_train, config);
        else
            vocabulary = vocabs(length(parts)+1);
        end
        [hists_train] = vlfeatFeatureExtractionVlad(images_train, vocabulary, config);

        if strcmp(config.useFlipped,'yes')
            flipConfig = config;
            flipConfig.preprocessing_flipImage = 1;
            [hists_train_flipped] = vlfeatFeatureExtractionVlad(images_train, vocabulary, flipConfig);                
            hists_train = [hists_train; hists_train_flipped];
        end

        
        
        config = prepareConfigForParts(images_test, parts_test, pi, config);
        [hists_test] = vlfeatFeatureExtractionVlad(images_test, vocabulary, config);
        
        parts(end).hists_train = hists_train;
        parts(end).hists_test = hists_test;
        parts(end).vocabulary = vocabulary;
    end
    
    
    for pi = [7 8 9]
        parts(end+1).name = [ part_names{pi} ' and ' part_names{pi+4} ' (' config.featureExtractFun ')' ];
        fprintf('compute features for double part %d (%s)\n',pi,parts(end).name);

        config = prepareConfigForParts(images_train, parts_train, pi, config);

        if isempty(vocabs)
            [vocabulary] = vlfeatCreateCodebookAib(images_train, labels_train, config);
        else
            vocabulary = vocabs(length(parts)+1);
        end

        [hists_train] = vlfeatFeatureExtractionVlad(images_train, vocabulary, config);
        if strcmp(config.useFlipped,'yes')
            flipConfig = config;
            flipConfig.preprocessing_flipImage = 1;
            [hists_train_flipped] = vlfeatFeatureExtractionVlad(images_train, vocabulary, flipConfig);                
            hists_train = [hists_train; hists_train_flipped];
        end

        config = prepareConfigForParts(images_train, parts_train, pi+4, config);
        [hists_train2] = vlfeatFeatureExtractionVlad(images_train, vocabulary, config);
        if strcmp(config.useFlipped,'yes')
            flipConfig = config;
            flipConfig.preprocessing_flipImage = 1;
            [hists_train2_flipped] = vlfeatFeatureExtractionVlad(images_train, vocabulary, flipConfig);                
            hists_train2 = [hists_train2; hists_train2_flipped];
        end

        config = prepareConfigForParts(images_test, parts_test, pi, config);
        [hists_test] = vlfeatFeatureExtractionVlad(images_test, vocabulary, config);

        config = prepareConfigForParts(images_test, parts_test, pi+4, config);
        [hists_test2] = vlfeatFeatureExtractionVlad(images_test, vocabulary, config);

        hists_test = max(hists_test, hists_test2);
        hists_train = max(hists_train, hists_train2);

        parts(end).hists_train = hists_train;
        parts(end).hists_test = hists_test;
        parts(end).vocabulary = vocabulary;

    end
    part_features = parts;
end

function config = prepareConfigForParts(images, parts, pi, config)

    parts_idxs = (pi*2-1):(pi*2);
        
    if strcmp(config.rotateParts,'yes')
        config.preprocessFunction = @preprocessExtractPatchAtPositionAndRotate;
        part_pairs =  [10     6     4     3     6     5     9    12     7     5    13     8    11    12     6];
%         part_pairs(:) = 15;
    else
        config.preprocessFunction = @preprocessExtractPatchAtPosition;
        part_pairs = 1:15;
    end
    
    pi2 = part_pairs(pi);
    parts2_idxs = (pi2*2-1):(pi2*2);

    args = {};
    args{1} = images;
    args{2} = [ parts(:,parts_idxs) repmat(config.preprocessing_relativePartSize,size(parts,1),1)];
    args{3} = parts(:,parts2_idxs);
    config.preprocessFunctionArgs = args;
end

function [im, bbox] = preprocessExtractPatchAtPosition(im,bbox,imagename,config)

    currentIdx = find(strcmp(config.preprocessFunctionArgs{1},imagename));
    
    params = config.preprocessFunctionArgs{2}(currentIdx,:);
    
    x = params(1);
    y = params(2);
    
%     if isfield(config,'preprocessing_flipImage') && config.preprocessing_flipImage == 1 && x ~= -1
%         x = size(im,1) - x;
%     end
    
    if x==-1 && y==-1 % part not present
        im = imcrop(im,[1,1,-1,-1]); % return an empty image
        bbox.left = 1;
        bbox.right = 1;
        bbox.top = 1;
        bbox.bottom = 1;
    else
        bbox_width = bbox.right - bbox.left;
        bbox_height = bbox.bottom - bbox.top;
        
        width = sqrt(bbox_width*bbox_height*params(3)); % in percent, to account for variations in image size
        % param(3) encodes percentage of the area a single part occupies
    
        xmin = x-width/2;
        ymin = y-width/2;
        width = width;
        height = width;

        im = imcrop(im,[xmin, ymin, width, height]);
        bbox.left = 1;
        bbox.right = size(im,2);
        bbox.top = 1;
        bbox.bottom = size(im,1);
    end
end


function [im, bbox] = preprocessExtractPatchAtPositionAndRotate(im,bbox,imagename,config)

    currentIdx = find(strcmp(config.preprocessFunctionArgs{1},imagename));
    
    params = config.preprocessFunctionArgs{2}(currentIdx,:);
    
    x = params(1);
    y = params(2);
    
    params2 = config.preprocessFunctionArgs{3}(currentIdx,:);
    x2 = params2(1);
    y2 = params2(2);
    
    theta = atan2(x-x2,y-y2);
    
%     if isfield(config,'preprocessing_flipImage') && config.preprocessing_flipImage == 1 && x ~= -1
%         x = size(im,1) - x;
%     end
    
    if x==-1 && y==-1 % part not present
        im = imcrop(im,[1,1,-1,-1]); % return an empty image
        bbox.left = 1;
        bbox.right = 1;
        bbox.top = 1;
        bbox.bottom = 1;
    else
        bbox_width = bbox.right - bbox.left;
        bbox_height = bbox.bottom - bbox.top;

        width = sqrt(bbox_width*bbox_height*params(3)); % in percent, to account for variations in image size
        % param(3) encodes percentage of the area a single part occupies

        width = width;
        height = width;
        if x2==-1 && y2 == -1
            xmin = x-width/2;
            ymin = y-width/2;
            im = imcrop(im,[xmin, ymin, width, height]);
        else
            im = rotcrop(im,theta,[x y],[width width]);
        end
        bbox.left = 1;
        bbox.right = size(im,2);
        bbox.top = 1;
        bbox.bottom = size(im,1);
    end
end

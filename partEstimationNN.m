function [parts_test_estimated,parts_train_estimated,confDiffString] = partEstimationNN(dataset, nrClasses, resDir, conf)
%partEstimationNN Estimates parts using the nearest neighbor method

	if nargin < 1
		dataset = 'cub200_2011';
	end
	
	if nargin < 2
		nrClasses = 200;
    end

    if nargin < 3
		resDir = '/tmp/';
	end

	if nargin < 4
		conf = struct([]);
	end

    configDefault.preprocessing_cropToBoundingbox = 1;
    configDefault.preprocessing_standardizeImage = 1;
    configDefault.preprocessing_standardizeImageSize = [128 128];
    configDefault.preprocessing_useMask = 'none';
    configDefault.hog_cellsize = 16;
    configDefault.partEstimation_distanceMeasure = 'euclidean';

	configDefault.k=1;

    [config,confDiffString] = parseConfigs(configDefault, conf);

	featureCacheFile = [resDir 'cache_' mfilename confDiffString '.mat']; 
	if exist(featureCacheFile,'file')
        load(featureCacheFile,'parts_test_estimated','parts_train_estimated');
    else
        fprintf('%s does not exist. Start computing features.\n',featureCacheFile);
        tic;
	
		[images_train, labels_train, images_test, labels_test] = getDataset(dataset,'imagenames',nrClasses);
		[parts_train, ~, parts_test, ~] = getDataset(dataset,'parts',nrClasses);
		[bbox_train, ~, bbox_test, ~] = getDataset(dataset,'bboxes',nrClasses);
	
	
	
	    hog_train = [];
	    hog_train_flipped = [];
	
	    parfor ii = 1:length(images_train)
	%     for ii = 1:length(images_train)
	        if mod(ii,10) == 0
	            fprintf('%d/%d\n',ii,length(images_train));
	        end
	        image_name = images_train{ii};
	
	        im = readImage(image_name, config);
	        mask = readMask(image_name, config);
	        mask(:,:,2) = mask(:,:,1);
	        mask(:,:,3) = mask(:,:,1);
	        im(mask==0)=0;
	        
	        hog = vl_hog(im2single(im),config.hog_cellsize);
	        hog_train(ii,:) = hog(:);
	
	        im_flipped = flipdim(im,2);
	        hog = vl_hog(im2single(im_flipped),config.hog_cellsize);
	        hog_train_flipped(ii,:) = hog(:);
	
	    end
	    
	    
	    hog_test = [];
	
	    parfor ii = 1:length(images_test)
	%     for ii = 1:length(images_test)
	        if mod(ii,10) == 0
	            fprintf('%d/%d\n',ii,length(images_test));
	        end
	        image_name = images_test{ii};
	
	        im = readImage(image_name, config);
	        mask = readMask(image_name, config);
	        mask(:,:,2) = mask(:,:,1);
	        mask(:,:,3) = mask(:,:,1);
	        im(mask==0)=0;

	        hog = vl_hog(im2single(im),config.hog_cellsize);
	        hog_test(ii,:) = hog(:);
	    end
	    
	    
	    hog_train_both = [hog_train; hog_train_flipped];
	    
	    [a]=pdist2(hog_train_both,hog_test,config.partEstimation_distanceMeasure);
	    [d,e]=sort(a);    
	    c = e(config.k,:);
% 	    [b,c]=min(a);
	    
	
		parts_test_estimated = [];
	
	    for ii = 1:length(images_test)
	    	ii
	%        imtest = readImage(images_test{ii},config);
	%        imnn = readImage(images_train{mod( c(ii) - 1, length(images_train))+1},config);
	
	        bestIdx = mod( c(ii) - 1, length(images_train))+1;
	        flip = c(ii) > length(images_train);
	
	        current_parts = parts_train(bestIdx,:);
	        current_parts_norm = (current_parts - repmat([bbox_train{bestIdx}.left bbox_train{bestIdx}.top],1,15)) ./ repmat([bbox_train{bestIdx}.right-bbox_train{bestIdx}.left bbox_train{bestIdx}.bottom-bbox_train{bestIdx}.top],1,15);        
	        current_parts_norm(current_parts == -1) = -1;
	        if flip
	            current_parts_norm(1:2:end) = 1 - current_parts_norm(1:2:end);
	            current_parts_norm(current_parts == -1) = -1;
	            tmp = current_parts_norm(13:18);
	            current_parts_norm(13:18) = current_parts_norm(21:26);
	            current_parts_norm(21:26) = tmp;
	        end
	        
	        
	        current_parts_norm_trans = (current_parts_norm .* repmat([bbox_test{ii}.right-bbox_test{ii}.left bbox_test{ii}.bottom-bbox_test{ii}.top],1,15)) + repmat([bbox_test{ii}.left bbox_test{ii}.top],1,15);        
	        current_parts_norm_trans(current_parts_norm==-1) = -1;
	        current_parts_norm_trans = round(current_parts_norm_trans);
	        
	        parts_test_estimated(ii,:) = current_parts_norm_trans;
	        
	%        if c(ii) > length(images_train)
	%            imnn = flipdim(imnn,2);
	%        end
	%        c(ii)
	%        
	%        subplot(1,2,1);
	%        imshow(imtest);
	%        subplot(1,2,2);
	%        imshow(imnn);
	%        waitforbuttonpress
	    end
	    
	    
	    [a]=pdist2(hog_train_both,hog_train);
	    % [b,c]=min(a);
	    [d,e]=sort(a);    
	    c = e(2,:);
	    c2 = e(3,:);
	    
	    
		parts_train_estimated = [];
	
	    for ii = 1:length(images_train)
	    	ii
	    	
	    	tmpcc = e(:,ii);
	    	tmpcc(tmpcc == ii | tmpcc == ii+length(images_train)) = [];
	    	c(ii) = tmpcc(config.k);
	    	
	%        imtest = readImage(images_test{ii},config);
	%        imnn = readImage(images_train{mod( c(ii) - 1, length(images_train))+1},config);
	
	        bestIdx = mod( c(ii) - 1, length(images_train))+1;
	        flip = c(ii) > length(images_train);
	        
	        if ii == bestIdx
	            bestIdx = mod( c2(ii) - 1, length(images_train))+1;
	            flip = c2(ii) > length(images_train);
	            
	            assert(ii ~= bestIdx);
	        end
	
	        current_parts = parts_train(bestIdx,:);
	        current_parts_norm = (current_parts - repmat([bbox_train{bestIdx}.left bbox_train{bestIdx}.top],1,15)) ./ repmat([bbox_train{bestIdx}.right-bbox_train{bestIdx}.left bbox_train{bestIdx}.bottom-bbox_train{bestIdx}.top],1,15);        
	        current_parts_norm(current_parts == -1) = -1;
	        if flip
	            current_parts_norm(1:2:end) = 1 - current_parts_norm(1:2:end);
	            current_parts_norm(current_parts == -1) = -1;
	            tmp = current_parts_norm(13:18);
	            current_parts_norm(13:18) = current_parts_norm(21:26);
	            current_parts_norm(21:26) = tmp;
	        end
	        
	        
	        current_parts_norm_trans = (current_parts_norm .* repmat([bbox_train{ii}.right-bbox_train{ii}.left bbox_train{ii}.bottom-bbox_train{ii}.top],1,15)) + repmat([bbox_train{ii}.left bbox_train{ii}.top],1,15);        
	        current_parts_norm_trans(current_parts_norm==-1) = -1;
	        current_parts_norm_trans = round(current_parts_norm_trans);
	        
	        parts_train_estimated(ii,:) = current_parts_norm_trans;
	        
	%        if c(ii) > length(images_train)
	%            imnn = flipdim(imnn,2);
	%        end
	%        c(ii)
	%        
	%        subplot(1,2,1);
	%        imshow(imtest);
	%        subplot(1,2,2);
	%        imshow(imnn);
	%        waitforbuttonpress
	    end
	    
	    
	    save(featureCacheFile,'parts_test_estimated','parts_train_estimated');
    end
end
    
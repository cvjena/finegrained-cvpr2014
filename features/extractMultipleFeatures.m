function features = extractMultipleFeatures(dataset, nrClasses, config, vocabs)
%extractMultipleFeatures extracts features for each of the functions given
%in config.featureExtractFuns

    [images_train, labels_train, images_test, ~ ] = getDataset(dataset,'imagenames',nrClasses);

    if iscell(config.featureExtractFuns{1}) % hack to make the config stuff work
        config.featureExtractFuns = config.featureExtractFuns{1};
    end
    
    for ii = 1:length(config.featureExtractFuns)
        config.featureExtractFun = config.featureExtractFuns{ii};
        
        if isempty(vocabs)
            [vocabulary] = vlfeatCreateCodebookAib(images_train, labels_train, config);
        else
            vocabulary = vocabs(ii);
        end
        config.preprocessing_flipImage = 0;
        [hists_train] = vlfeatFeatureExtractionVlad(images_train, vocabulary, config);
        
        if strcmp(config.useFlipped,'yes')
            % also compute features of the flipped version of the images
            % and append them to the results
	        config.preprocessing_flipImage = 1;
    	    [hists_train_flipped] = vlfeatFeatureExtractionVlad(images_train, vocabulary, config);

			hists_train = [hists_train; hists_train_flipped];
		end

        config.preprocessing_flipImage = 0;
        [hists_test] = vlfeatFeatureExtractionVlad(images_test, vocabulary, config);
            

        features(ii).hists_train = hists_train;
        features(ii).hists_test = hists_test;
        features(ii).vocabulary = vocabulary;
        features(ii).name = ['global ' config.featureExtractFuns{ii}];
    end

end
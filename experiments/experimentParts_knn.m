function recRate = experimentParts_knn(dataset,nrClasses, conf, confPart)
%experimentParts_knn uses the k best part estimations to compute the final
%classification result

    maxK = 20;

    gtid = tic;
    if nargin < 1
        dataset = 'cub200_2011';
    end
    
    if nargin < 2
        nrClasses = 14;
    end
    if nargin < 3
    	conf = struct([]);
    end

    % the standard is to use some parts
    % FIXME: is there another suitable option at all?
    if nargin < 4
    	confPart = struct([]);
    	confPart.useParts = 'nn';
    end

    % change the outputdir in the file settings.m
    setts = settings();

    % create the directory used to store the results,
    % in my case: /home/rodner/experiments/finegrained/results/cub200_2011/gcpr_parts/14
    resDir = [setts.outputdir '/' dataset '/gcpr_parts/' num2str(nrClasses) '/'];
    if ~exist(resDir,'dir')
        mkdir(resDir);
    end
    
    % extract global features for the whole dataset
    [features, time_features, config, confDiffString] = experimentGeneral_extractGlobalFeatures(dataset, nrClasses, resDir, conf);
    
    
    for k=1:1
        confPart(1).k=k;
        [partFeatures, ~, configParts, confPartDiffString] = experimentGeneral_extractPartFeatures(dataset, nrClasses, resDir, confPart);
    end
    
    [~, labels_train, ~, labels_test ] = getDataset(dataset,'imagenames',nrClasses);
    if strcmp(config.useFlipped,'yes') && ~strcmp(configParts.useFlipped,'yes')
		for pi = 1:length(partFeatures)
			partFeatures(pi).hists_train = [partFeatures(pi).hists_train;partFeatures(pi).hists_train];
		end
    elseif strcmp(config.useFlipped,'yes') && ~strcmp(configParts.useFlipped,'yes')
		for pi = 1:length(features)
			features(pi).hists_train = [features(pi).hists_train;features(pi).hists_train];
		end
    end
        
    if strcmp(config.useFlipped,'yes') || strcmp(configParts.useFlipped,'yes')
		labels_train = [labels_train; labels_train];
    end

    if ~isempty(features)
        if ~isfield(features,'name')
            features(1).name = '';
            features(1).vocabulary = []; 
        end
    end

    scores = {};
    for k=1:maxK 
        fprintf('Compute scores for k=%d\n',k);
        tic;
        confPart(1).k=k;
        [partFeatures, ~, ~, ~] = experimentGeneral_extractPartFeatures(dataset, nrClasses, resDir, confPart);
        features_com = [features partFeatures];
        hists_train = cat(2,features_com.hists_train);
        hists_test = cat(2,features_com.hists_test);
        [ recRate(k), ~, scores{k}, ~] = liblinearTrainTest( hists_train, labels_train, hists_test, labels_test, config );
     	[~,labels_est{k}]=max(scores{k});
     	labels_correct{k} = labels_est{k} == labels_test';
        toc
    end

    if ~strcmp(configParts.noisyTrainingParts,'no')
        labels_train = repmat(labels_train, configParts.noisyTrainingPartsFactor, 1);
    end
    
%    recRates_parts = [];
%    mAP_parts = [];
%    for fi = 1:length(features)
%        tid_part = tic;
%        [ recRates_parts(fi), ~, scores, ~] = liblinearTrainTest( features(fi).hists_train, labels_train, features(fi).hists_test, labels_test, config );
%        mAP_parts(fi) = mean(evalAP(scores, labels_test));
%        part_time = toc(tid_part);
%        fprintf('train part model %d/%d (%.2f)\n',fi,length(features),part_time )
%    end


%    hists_train = cat(2,features.hists_train);
%    hists_test = cat(2,features.hists_test);

%     [~, labels_train, ~, labels_test ] = getDataset(dataset,'imagenames',nrClasses);
 

	labels_correct_all = sum(cat(1,labels_correct{:}));
	recRate_all = mean(labels_correct_all > 0)        
    
    recRate
    
    for ii=1:length(labels_est)
        if ii==1
            recRate_vote(ii) = mean(labels_est{1}==labels_test');
            recRate_mean(ii) = mean(labels_est{1}==labels_test');
        else
            a=hist( cat(1,labels_est{1:ii}), 1:nrClasses);
            [~,b]=max(a);
            recRate_vote(ii) = mean(b==labels_test');
            
            [~,b]=max(mean(cat(3,scores{1:ii}),3));
            recRate_mean(ii) = mean(b==labels_test');
        end
    end
    
    plot([recRate_mean;recRate_vote]')
    
    recRate_vote
    recRate_mean
    
%    mAP = mean(evalAP(scores, labels_test))

    clear features
    clear partFeatures
    clear hists_train
    clear hists_test
    
    file = [resDir mfilename confDiffString confPartDiffString '.mat'];
%     file = [resDir 'globalGeneral_w' num2str(config.numWords) '_dict' config.codebookClusterAlgorithm  ...
%         '_dictcomp' config.codebookCompression num2str(config.codebookCompressionSize) ...
%         '_descr' config.descriptor '_pca' config.usePCACompression num2str(config.PCACompressionSize)  '_parts' configParts.useParts ...
%         '_global' config.useGlobal ...
%         '_noisyTrainParts' configParts.noisyTrainingParts '_' num2str(configParts.noisyTrainingPartsSigma) '_' num2str(configParts.noisyTrainingPartsFactor) ...
%         '_flipped' config.useFlipped  '.mat'];
    save(file,'-v7.3');
    
    toc(gtid)
end

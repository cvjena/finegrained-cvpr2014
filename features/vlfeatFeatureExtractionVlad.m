% Perform pooling and coding
% with VLAD or standard techniques
% http://www.vlfeat.org/sandbox/api/vlad-fundamentals.html
% Many many more options, like PCA
%
% For histograms, L1 normalization is always performed.
function [hists] = vlfeatFeatureExtractionVlad(images, vocabModel, config)

% default conifg
conf.numWords = 500;
conf.numSpatialX = [2 4]; 
conf.numSpatialY = [2 4];
conf.quantizer = 'kdtree' ;
conf.phowOpts = {'Step', 3, 'Color','opponent'} ;
conf.randSeed = 1 ;
conf.preprocessing_useGrabcutMask = false;
conf.preprocessing_cropToBoundingbox = false;
conf.preprocessing_standardizeImage = true;
conf.preprocessing_standardizeImageSize = 480;
conf.vocabSubset = 30;
conf.basedir = [getenv('HOME') '/'];
conf.excludeGTBoundingBoxes = false;
conf.featureExtractFun = @extractSiftFeatures;

% config merge
if exist('config','var')
    for field = fieldnames(config)'
        conf.(field{1}) = config.(field{1}); % why is {1} necessary?
    end
end

model = vocabModel;
model.vocabMap = model.map;
model.quantizer = conf.quantizer;
model.numSpatialX = conf.numSpatialX;
model.numSpatialY = conf.numSpatialY;
  % model.vocab = vocabModel.vocab;
  % model.vocabMap= vocabModel.map;
  % model.kdtree = vocabM

  randn('state',conf.randSeed) ;
  rand('state',conf.randSeed) ;
  vl_twister('state',conf.randSeed) ;

  % if strcmp(conf.quantizer, 'kdtree')
  %   model.kdtree = vl_kdtreebuild(vocabulary) ;
  % end

  % --------------------------------------------------------------------
  %                                           Compute spatial histograms
  % --------------------------------------------------------------------
  fprintf('Compute spatial histograms for %s (%d images)\n', conf.featureExtractFun, length(images));
  featureExtractFun = str2func(conf.featureExtractFun);

    nrDots = 10;
    modValue = ceil(length(images)/nrDots);

    hists = {} ;
    %times = [];
    tic;
    ticId = tic;

    % loop through all images
    parfor ii = 1:length(images)
  % for ii = 1:length(images)

      % extract local features
      [descrs, frames, imSize] = featureExtractFun(images{ii}, conf);
      
      % PCA compress local features if necessary
      if strcmp(conf.usePCACompression,'yes')
          descrs = (model.pcaTrans' * (single(descrs) - repmat(model.pcaTransMean,size(descrs,2),1)'));
      end

      % perform coding and pooling 
      if strcmp(conf.descriptor,'histogram')                

          hists{ii} = getImageDescriptor(model, imSize, frames, descrs);
      elseif strcmp(conf.descriptor,'vlad')
          % http://www.vlfeat.org/sandbox/api/vlad-fundamentals.html
          hists{ii} = getImageDescriptorVlad(model, imSize, frames, descrs);
      else
          error('unknown option');
      end

      %times(ii) = toc(ticId);
      %fprintf('%.3f s (%.1f min)\n', times(ii), mean(times)*(length(images)-ii)/60) ;
      %fprintf('Vlfeat: Processing %s (%.2f %%) ', images{ii}, 100 * ii / length(images)) ;
      
      % output some progress
      if mod(ii,modValue)==0
          fprintf(' - %.2f %% ', 100 * ii / length(images));
          fprintf('%.3f s \n', toc(ticId)) ;
      end
    end
    fprintf('\n');
    toc
    hists = cat(1, hists{:}) ;


  % -------------------------------------------------------------------------
function hist = getImageDescriptorVlad(model, imSize, frames, descrs)
% -------------------------------------------------------------------------
% very similar to getImageDescriptorHistogram, but use VLAD coding and pooling

width = imSize(2) ;
height = imSize(1) ;
numWords = max(model.vocabMap) ; 
 
% quantize appearance
switch model.quantizer
  case 'vq'
    [~,binsa]=min(pdist2(model.vocab',single(descrs')));
  case 'kdtree'
    binsa = double(vl_kdtreequery(model.kdtree, model.vocab, ...
                                  single(descrs), ...
                                  'MaxComparisons', 15)) ;
end

binsa = model.vocabMap(binsa);

% spatial pooling
for i = 1:length(model.numSpatialX)
  binsx = vl_binsearch(linspace(1,width+1,model.numSpatialX(i)+1), frames(1,:)) ;
  binsy = vl_binsearch(linspace(1,height+1,model.numSpatialY(i)+1), frames(2,:)) ;

  % combined quantization
  bins = sub2ind([model.numSpatialY(i), model.numSpatialX(i), numWords], ...
                 binsy,binsx,binsa) ;
             
  vladBins = reshape(repmat(bins,size(descrs,1),1)-1,size(descrs,1)*length(bins),1)'*size(descrs,1) + repmat(1:size(descrs,1),1,length(bins));
             
  hist = zeros(model.numSpatialY(i) * model.numSpatialX(i) * numWords * size(descrs,1), 1) ;
  hist = vl_binsum(hist, double(reshape(model.vocab(:,binsa) - single(descrs),prod(size(descrs)),1)), vladBins) ;
  
  % again L1-normalization 
  hists{i} = single(hist / norm(hist,2)) ;
end
hist = cat(1,hists{:}) ;
if size(frames,2) == 0 % in case no features were found in the image, set everything to zero
    hist(:) = 0;
end

hist = hist';


% -------------------------------------------------------------------------
function hist = getImageDescriptor(model, imSize, frames, descrs)
% -------------------------------------------------------------------------
% Standard BoW pooling and coding

width = imSize(2) ;
height = imSize(1) ;
numWords = max(model.vocabMap) ; 
 
% quantize appearance
switch model.quantizer
  case 'vq'
    % an equivalent but slower alternative (?)
    % [drop, binsa] = min(vl_alldist(model.vocab, single(descrs)), [], 1) ;
    
    % determine the nearest neighbour codebook element for each local descriptor
    [~,binsa]=min(pdist2(model.vocab',single(descrs')));

  case 'kdtree'
    % use a KD-tree to speed up nearest neighbour search
    binsa = double(vl_kdtreequery(model.kdtree, model.vocab, single(descrs), 'MaxComparisons', 15)) ;
end

% map codebook indices to bins?
binsa = model.vocabMap(binsa);

% perform spatial pooling
for i = 1:length(model.numSpatialX)
  binsx = vl_binsearch(linspace(1,width+1,model.numSpatialX(i)+1), frames(1,:)) ;
  binsy = vl_binsearch(linspace(1,height+1,model.numSpatialY(i)+1), frames(2,:)) ;

  % combined quantization
  bins = sub2ind([model.numSpatialY(i), model.numSpatialX(i), numWords], ...
                 binsy,binsx,binsa) ;
  hist = zeros(model.numSpatialY(i) * model.numSpatialX(i) * numWords, 1) ;
  hist = vl_binsum(hist, ones(size(bins)), bins) ;

  % L1-normalization
  hists{i} = single(hist / sum(hist)) ;
end

% combine all the histograms of the pooling regions
hist = cat(1,hists{:}) ;
if size(frames,2) == 0 % in case no features were found in the image, set everything to zero
    hist(:) = 0;
end

hist = hist';


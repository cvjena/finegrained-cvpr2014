function sets = settings()
%SETTINGS Global settings like pathes to libraries and datasets

    sets.libraries_vlfeatDir = [ getenv('HOME') '/thirdParty/vlfeat/toolbox'];
    sets.libraries_liblinear = [getenv('HOME') '/thirdParty/liblinear-1.93/matlab']; 
    sets.libraries_yael = [getenv('HOME') '/thirdParty/yael_v318/matlab']; 
    sets.libraries_colornames = [getenv('HOME') '/thirdParty/ColorNaming/'];
    sets.dataset_cub200_2011 = ['/home/dbv/bilder/FineGrained/CUB_200_2011/'];
    sets.outputdir = [getenv('HOME') '/experiments/finegrained/results/'];
    sets.cachedir =  [getenv('HOME') '/experiments/finegrained/cache/'];
end

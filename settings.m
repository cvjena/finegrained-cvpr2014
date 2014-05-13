function sets = settings()
%SETTINGS Global settings like pathes to libraries and datasets


    if strcmp( getenv('USER'), 'rodner')
        sets.libraries_vlfeatDir = [ getenv('HOME') '/thirdParty/vlfeat/toolbox'];
        sets.libraries_liblinear = [getenv('HOME') '/thirdParty/liblinear-1.93/matlab']; 
        sets.libraries_yael = [getenv('HOME') '/thirdParty/yael_v318/matlab']; 
        sets.libraries_colornames = [getenv('HOME') '/thirdParty/ColorNaming/'];
        sets.libraries_who = [getenv('HOME') '/dev/who/' ];
        
        sets.dataset_cub200_2011 = ['/home/dbv/bilder/FineGrained/CUB_200_2011/'];
        sets.outputdir = [getenv('HOME') '/experiments/finegrained/results/'];
        sets.cachedir =  [getenv('HOME') '/experiments/finegrained/cache/'];  
        
        sets.dpmestimatesdir = '/home/rodner/data/finegrained-dpm-parts/dpm_parts';
        
    elseif strcmp( getenv('USER'), 'freytag')
        sets.libraries_vlfeatDir = [ getenv('HOME') '/code/3rdParty/vlfeat/toolbox'];
        sets.libraries_liblinear = [getenv('HOME') '/code/3rdParty/liblinear-1.93/matlab']; 
        sets.libraries_yael = [getenv('HOME') '/code/3rdParty/yael_v318/matlab']; 
        sets.libraries_colornames = [getenv('HOME') '/code/3rdParty/ColorNaming/'];
        sets.libraries_who = [getenv('HOME') '/dev/who/' ];
        
        sets.dataset_cub200_2011 = ['/home/dbv/bilder/FineGrained/CUB_200_2011/'];
        sets.outputdir = [getenv('HOME') '/experiments/finegrained/results/'];
        sets.cachedir =  [getenv('HOME') '/experiments/finegrained/cache/'];  
        
        sets.dpmestimatesdir = '/home/rodner/data/finegrained-dpm-parts/dpm_parts';
        
    else
        sets.libraries_vlfeatDir = [ getenv('HOME') '/thirdParty/vlfeat/toolbox'];
        sets.libraries_liblinear = [getenv('HOME') '/thirdParty/liblinear-1.93/matlab']; 
        sets.libraries_yael = [getenv('HOME') '/thirdParty/yael_v318/matlab']; 
        sets.libraries_colornames = [getenv('HOME') '/thirdParty/ColorNaming/'];
        sets.libraries_who = [getenv('HOME') '/dev/who/' ];
        
        sets.dataset_cub200_2011 = ['/home/dbv/bilder/FineGrained/CUB_200_2011/'];
        sets.outputdir = [getenv('HOME') '/experiments/finegrained/results/'];
        sets.cachedir =  [getenv('HOME') '/experiments/finegrained/cache/'];        
        
        sets.dpmestimatesdir = '/home/rodner/data/finegrained-dpm-parts/dpm_parts';
    end
end

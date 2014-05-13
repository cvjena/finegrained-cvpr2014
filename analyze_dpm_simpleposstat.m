%% Analyze the distribution of part positions
% This MATLAB script can be used to reproduce Figure 2 in the paper
%
function analyze_dpm(partid, nrClasses, dataset)
    if nargin < 3
		dataset = 'cub200_2011';
    end
	
    
	if nargin < 2
		nrClasses = 14;
    end

    if nargin < 1
        partid = 1;
    end

    part_names = {'back' 'beak' 'belly' 'breast' 'crown' 'forehead' 'left eye' 'left leg' 'left wing' 'nape' 'right eye' 'right leg' 'right wing' 'tail' 'throat'};
    
    fprintf('Analyzing part: %s\n', part_names{partid});

    fprintf('loading image information\n');
    [images_train, labels_train, images_test, labels_test] = getDataset(dataset,'imagenames',nrClasses);
    fprintf('loading part information\n');
    [parts_train, ~, parts_test, ~] = getDataset(dataset,'parts',nrClasses);
    fprintf('loading bounding box information\n');
    [bbox_train, ~, bbox_test, ~] = getDataset(dataset,'bboxes',nrClasses);
    
    X = parts_train(:,(2*partid-1):(2*partid));
    unlabeled = (X(:,1) == -1);
    bbox = bbox_train;
    
    config = struct([]);
    
    % normalization using the bounding box
    for i=1:size(X,1)
        image_name = images_train{i};
        im = readImage(image_name, config);
        imshow(im);
        rectangle('Position', [ bbox{i}.left, bbox{i}.top, ...
            bbox{i}.right - bbox{i}.left + 1, bbox{i}.bottom - bbox{i}.top + 1, ], ...
            'EdgeColor', 'red', 'LineWidth', 2 );
        s = 10;
        rectangle('Position', [ X(i,1)-s, X(i,2)-s, 2*s, 2*s ], ...
            'EdgeColor', 'blue', 'LineWidth', 2);
        pause;
        
        X(i,:) = (X(i,:) - [bbox{i}.left bbox{i}.top]) ./ ...
            [bbox{i}.right-bbox{i}.left bbox{i}.bottom - bbox{i}.top];        
    end
    
    filter_sides = true;
    if filter_sides
        beakid = 2;
        tailid = 14;
        otherside = parts_train(:, 2*beakid-1) < parts_train(:, 2*tailid-1);
        X(or(unlabeled,otherside),:) = [];
    else
        X(unlabeled,:) = [];
    end
    
    size(X)
    plot( X(:,1), X(:,2), 'r+');
    xlabel('normalized x-coordinate');
    ylabel('normalized y-coordinate');
    title(sprintf('part %s', part_names{partid}));
    figureHandle = gcf;
    set(findall(figureHandle,'type','text'),'fontSize',18,'fontWeight','bold')
    
    fn = sprintf('%s_posstat.eps', part_names{partid});
    print (fn, '-depsc2');
    system(sprintf('epstopdf \"%s\"', fn));
end

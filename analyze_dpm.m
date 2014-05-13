function analyze_dpm(parts, nrClasses, dataset)
    if nargin < 3
		dataset = 'cub200_2011';
    end
	
    
	if nargin < 2
		nrClasses = 200;
    end

    if nargin < 1
        parts = [ 2, 3, 6, 14 ];
    end

    part_names = {'back    ' 'beak    ' 'belly    ' 'breast    ' 'crown    ' 'forehead' 'left eye' 'left leg' 'left wing' 'nape    ' 'right eye' 'right leg' 'right wing' 'tail    ' 'throat    '};
    
    fprintf('Analyzing parts: %s\n', part_names{parts});

    
    fprintf('loading part information\n');
    [parts_train, ~, parts_test, ~] = getDataset(dataset,'parts',nrClasses);
    fprintf('loading bounding box information\n');
    [bbox_train, ~, bbox_test, ~] = getDataset(dataset,'bboxes',nrClasses);
    
    X = parts_train;
    bbox = bbox_train;
    
    % we center everything to the belly
    centerpartid = 3;

    % normalization using the bounding box
    Xn = zeros(size(X));
    for i=1:size(X,1)
        Xn(i,:) = (X(i,:) - repmat( [bbox{i}.left bbox{i}.top], 1, 15) ) ./ ...
            repmat([bbox{i}.right-bbox{i}.left bbox{i}.bottom - bbox{i}.top], 1, 15);        
        
        % center        
        Xn(i,:) = -( Xn(i,:) - repmat( Xn(i,(2*centerpartid-1):(2*centerpartid)), 1, 15 ) );
    end
    
    
    close all;
    figure;
    styles = { 'r+', 'b+', 'ro', 'r+', 'r+', 'rx', 'r+', 'r+', 'r+', 'r+', 'r+', 'r+', 'r+', 'go', 'r+' };
    for k=1:length(parts)
        center_unlabeled = ( X(:, 2*centerpartid-1) == -1 );
        part_unlabeled = ( X(:, 2*parts(k)-1) == -1 );
        labeled_elements = not ( or ( center_unlabeled, part_unlabeled ) );
        
        plot( Xn(labeled_elements, 2*parts(k)-1), Xn(labeled_elements, 2*parts(k)), styles{parts(k)} ); hold on;
        
    end
    
    legend( part_names{parts} );
    
    % X = X(:,(2*partid-1):(2*partid));
    % X(unlabeled,:) = [];
    
    
    
    
end
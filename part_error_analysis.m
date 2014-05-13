function part_error_analysis(dataset, nrClasses)

    if nargin < 1
		dataset = 'cub200_2011';
	end
	
	if nargin < 2
		nrClasses = 200;
    end

    sets = settings();
    
    %partinfo = sprintf('%s/%s/gcpr_parts/%d/cache_partEstimationNN_c-useParts-nn.mat', sets.outputdir, dataset, nrClasses);
    
    tags = { 'nn_c-useParts-nn', 'dpm' };
    
    for ti=1:2
        partinfo = sprintf('%s/%s/gcpr_parts/%d/cache_partGeneralFeatures_c-useParts-%s.mat', sets.outputdir, dataset, nrClasses, tags{ti});


        p_est = load(partinfo);

        [parts_train, ~, parts_test, ~] = getDataset(dataset,'parts',nrClasses);
        [bbox_train, ~, bbox_test, ~] = getDataset(dataset,'bboxes',nrClasses);

        part_names = {'back' 'beak' 'belly' 'breast' 'crown' 'forehead' 'left eye' 'left leg' 'left wing' 'nape' 'right eye' 'right leg' 'right wing' 'tail' 'throat'};
        
        if ti==1
            styles = {'r-' 'r-' 'r-' 'r-' 'b-' 'b-' 'g-' 'g-' 'g-' 'b-' 'g-' 'g-' 'g-' 'g-' 'g-'};
        else
            styles = {'r--' 'r--' 'r--' 'r--' 'b--' 'b--' 'g--' 'g--' 'g--' 'b--' 'g--' 'g--' 'g--' 'g--' 'g--'};
        end
        selected_parts = [ 1, 10, 8 ];


        hold on;

        for i=selected_parts

            r = (2*i-1):(2*i);;
            xest = p_est.parts_test_estimated(:,r);
            x    = parts_test(:,r);

            % take care of no labels for certain parts
            unknownpart = x(:,1)<0;
            unknownpartest = xest(:,1)<0;
            unknownpart = unknownpart | unknownpartest;

            % check if positions are outside of the bounding box
            validpos = zeros(size(x,1),1);
            for k=1:size(x,1)            
                validpos(k) = (xest(k,1) >= bbox_test{k}.left) & (xest(k,1) <= bbox_test{k}.right) & ...
                     (xest(k,2) >= bbox_test{k}.top) & (xest(k,2) <= bbox_test{k}.bottom);
                if ~validpos(k) && ~unknownpart(k)
                    %disp(bbox_test{k});
                    %disp(xest(k,:));
                    %(xest(k,1) >= bbox_test{k}.left)
                    %(xest(k,1) <= bbox_test{k}.right)
                    %(xest(k,2) >= bbox_test{k}.top)
                    %(xest(k,2) <= bbox_test{k}.bottom)
                end
            end

            % normalize positions
            nw = 1.0;
            nh = 1.0;
            for k=1:size(x,1)
                w = bbox_test{k}.right - bbox_test{k}.left + 1;
                h = bbox_test{k}.bottom - bbox_test{k}.top + 1;

                x(k,:) = (x(k,:) - [ bbox_test{k}.left, bbox_test{k}.top ]);           
                x(k,:) = x(k,:) .* [nw, nh] ./ [ w, h ];

                xest(k,:) = (xest(k,:) - [ bbox_test{k}.left, bbox_test{k}.top ]);           
                xest(k,:) = xest(k,:) .* [nw, nh] ./ [ w, h ];


            end

            x(unknownpart,:) = [];
            xest(unknownpart,:) = [];
            validpos(unknownpart,:) = [];

            fprintf('Number of non-valid positions (outside of bounding box): %d\n', size(x,1) - sum(validpos));
            fprintf('Number of positions: %d\n', size(x,1));


            % L1 error
            %errors = abs(x - xest);
            %errors = sum(errors,2);
            % normalized L2 error
            errors = sqrt(sum((x - xest).^2,2))/sqrt(2);
            sorted_errors = sort(errors);
            rank_range = [1:length(sorted_errors)] ./ length(sorted_errors);
            
            if ti==1
                linewidth = 5;
            else
                linewidth = 3;
            end
            
            plot(rank_range, sorted_errors, styles{i}, 'LineWidth', linewidth);


            %title(sprintf('%s (median=%f)', part_names{i}, median(sorted_errors)));



        end

        
        
    
    end
    
    legend(gca, sprintf('%s (Our approach)', part_names{selected_parts(1)}), ...
                sprintf('%s (Our approach)', part_names{selected_parts(2)}), ...
                sprintf('%s (Our approach)', part_names{selected_parts(3)}), ...
                sprintf('%s (DPM)', part_names{selected_parts(1)}), ...
                sprintf('%s (DPM)', part_names{selected_parts(2)}), ...
                sprintf('%s (DPM)', part_names{selected_parts(3)}), ...
                'Location', 'NorthWest');
    xlabel('normalized rank');
    ylabel({'normalized euclidean error','of part detection'});
    
    %set( lh, 'FontName', 'Helvetica', 'FontSize', 24);
    figureHandle = gcf;
    set(findall(figureHandle,'type','text'),'fontSize',26)
    hold off;
    
    print ('-depsc2', 'part-error-analysis.eps');
    system('epstopdf part-error-analysis.eps');
    
end

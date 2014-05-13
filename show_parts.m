function show_parts( parts, bbox, relsize )
    hold on;
    numparts = length(parts)/2;

    bbox_width = bbox.right - bbox.left;
    bbox_height = bbox.bottom - bbox.top;
        
    s = sqrt(bbox_width*bbox_height*relsize); % in percent, to account for variations in image size
    s = s/2;
    
    for i=1:numparts
        
       x = parts(2*i-1);
       y = parts(2*i);
       
       if x>=0
          rectangle('Position', [ x-s, y-s, 2*s, 2*s ], ...
                'EdgeColor', 'blue', 'LineWidth', 2); 
          hold on;
       end
        
    end

    rectangle('Position', [ bbox.left, bbox.top, ...
            bbox.right - bbox.left + 1, bbox.bottom - bbox.top + 1, ], ...
            'EdgeColor', 'red', 'LineWidth', 2 );
    hold on;
    
end
run('../vlfeat-0.9.21/toolbox/vl_setup')
load('my_svm.mat')

imageDir = 'test_images';
imageList = dir(sprintf('%s/*.jpg',imageDir));
nImages = length(imageList);

bboxes = zeros(0,4);
confidences = zeros(0,1);
image_names = cell(0,1);

cellSize = 6;
dim = 36;
for i=1:nImages
    close all
    
    % load and show the image
    im = im2single(imread(sprintf('%s/%s',imageDir,imageList(i).name)));
    imshow(im);
    hold on;
    
    % Setup different scales for predictions
    scales = 1:-0.05:0.2;
    
    % concatenate the features into 6x6 bins, and classify them (as if they
    % represent 36x36-pixel faces)     
    confs_orig = cell(size(scales));
    
    for s=1:numel(scales)
        % generate a grid of features across the entire image. you may want to 
        % try generating features more densely (i.e., not in a grid)
        im_curr = imresize(im, scales(s));
        feats = vl_hog(im_curr, cellSize);
        
        [rows,cols,~] = size(feats);
        confs_orig{s} = zeros(rows - 5, cols - 5);
        
        for r=1:rows-5
            for c=1:cols-5
                % create feature vector for the current window and classify it using the SVM model, 
                % take dot product between feature vector and w and add b,
                % store the result in the matrix of confidence scores confs(r,c)

                curr_feat = feats(r:r + 5, c:c + 5, :);
                confs_orig{s}(r, c) = dot(curr_feat(:), w) + b;
            end
        end
    end

    confs = zeros(size(confs_orig{1}, 1), size(confs_orig{1}, 2));
    conf_scales = zeros(size(confs_orig{1}, 1), size(confs_orig{1}, 2));
    
    for s=1:numel(scales)
        for r=1:size(confs_orig{s}, 1)
            for c=1:size(confs_orig{s}, 2)
                if confs(r, c) == 0 || confs_orig{s}(r, c) > confs(r, c)
                    confs(r, c) = confs_orig{s}(r, c);
                    conf_scales(r, c) = scales(s);
                end
            end
        end
    end
    
    % get the most confident predictions 
    [~,inds] = sort(confs(:),'descend');
    inds = inds(1:size(confs)); % (use a bigger number for better recall)
    
    final_ids = [];
    exclude = [];
    
    for n=1:numel(inds)        
        [row,col] = ind2sub([size(confs,1) size(confs,2)],inds(n));
        
        bbox = [ col*cellSize/conf_scales(row, col) ...
                 row*cellSize/conf_scales(row, col) ...
                (col+cellSize-1)*cellSize/conf_scales(row, col) ...
                (row+cellSize-1)*cellSize/conf_scales(row, col)];
        
        best = n;
        
        for j = 1:numel(inds)
            if n == j
                break;
            end
            
            [row_curr, col_curr] = ind2sub([size(confs,1) size(confs,2)],inds(j));
            
            bbox_curr = [ col_curr*cellSize/conf_scales(row_curr, col_curr) ...
                row_curr*cellSize/conf_scales(row_curr, col_curr) ...
                (col_curr+cellSize-1)*cellSize/conf_scales(row_curr, col_curr) ...
                (row_curr+cellSize-1)*cellSize/conf_scales(row_curr, col_curr)];
            bi=[max(bbox(1), bbox_curr(1)); max(bbox(2), bbox_curr(2)); ...
                min(bbox(3), bbox_curr(3)); min(bbox(4), bbox_curr(4))];
            iw=bi(3)-bi(1)+1;
            ih=bi(4)-bi(2)+1;
            if iw>0 && ih>0       
                % compute overlap as area of intersection / area of union
                ua=(bbox(3) - bbox(1) + 1) * (bbox(4) - bbox(2) + 1) + ...
                   (bbox_curr(3) - bbox_curr(1) + 1) * (bbox_curr(4) - bbox_curr(2) + 1) - ...
                   iw*ih;
                ov=iw*ih/ua;
                
                if ov > 0
                    if confs(inds(j)) > confs(inds(best))
                        exclude = [exclude; best];
                        best = j;
                    else
                        exclude = [exclude; j];
                    end
                end
            end
        end
        
        if ~any(final_ids(:) == best)
            final_ids = [final_ids; best];
        end
    end
    
    for j = 1:numel(final_ids)
        if any(exclude(:) == final_ids(j))
            continue;
        end
        
        [row,col] = ind2sub([size(confs,1) size(confs,2)], inds(final_ids(j)));

        bbox = [ col*cellSize/conf_scales(row, col) ...
            row*cellSize/conf_scales(row, col) ...
            (col+cellSize-1)*cellSize/conf_scales(row, col) ...
            (row+cellSize-1)*cellSize/conf_scales(row, col)];
        
        if bbox(1) > size(im, 2) || bbox(2) > size(im, 1) || ...
                bbox(3) > size(im, 2) || bbox(4) > size(im, 1)
            continue;
        end
        
        % plot
        plot_rectangle = [bbox(1), bbox(2); ...
            bbox(1), bbox(4); ...
            bbox(3), bbox(4); ...
            bbox(3), bbox(2); ...
            bbox(1), bbox(2)];
        plot(plot_rectangle(:,1), plot_rectangle(:,2), 'g-');
        
        image_name = {imageList(i).name};
        conf = confs(row,col);
        
        % save         
        bboxes = [bboxes; bbox];
        confidences = [confidences; conf];
        image_names = [image_names; image_name];
    end
    
    %pause;
    fprintf('got preds for image %d/%d\n', i,nImages);
end

% evaluate
label_path = 'test_images_gt.txt';
[gt_ids, gt_bboxes, gt_isclaimed, tp, fp, duplicate_detections] = ...
    evaluate_detections_on_test(bboxes, confidences, image_names, label_path);

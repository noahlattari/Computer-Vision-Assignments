% User-defined variables
distance_threshold = 5000; % Threshold for distance between matches
iterations = 150; % RANSAC iterations
p = 3000; % Matching threhold 

% Read Images
left_image = imread('parliament-left.jpg');
right_image = imread('parliament-right.jpg');

% Convert to single and to grayscale
left = single(rgb2gray(left_image));
right = single(rgb2gray(right_image));

%Get Descriptors
[f1, d1] = vl_sift(left);
[f2, d2] = vl_sift(right);

% Get Distances
% Using vl_ubcmatch since dist2 doesn't work when the 2 images are different
% sizes (current situation, get an error)
[matches, distances] = vl_ubcmatch(d1, d2);

% Select closest matches based on threshold
closest_matches = [];
for i = 1:size(matches, 2)
    if distances(i) < distance_threshold
        closest_matches(:, end + 1) = matches(:, i);
    end
end

best_fit = [];

% User tested required number of RANSAC iterations
for i = 1:iterations
    % Get 3 samples so we can get both T and c
    rand_sample = randperm(size(closest_matches, 2), 3); 
    
    % Get coordinates from sample
    x1 = zeros(2, 3);
    x2 = zeros(2, 3);
  
    % Gets first 2 elements of f1/f2 as those are the X,Y center of frame
    for j = 1:3
        % First index in closest match, matches f1 index
        x1(:, j) = f1(1:2, closest_matches(1, rand_sample(j)));
        % Second index in closest match, matches f2 index
        x2(:, j) = f2(1:2, closest_matches(2, rand_sample(j)));
    end
    
    % x2 = Tx1 + c
    % x = (T, c) -> 6x1 matrix (first 4 rows T, last 2 c)
    % A = (x1, ...) -> 6x6 matrix -> 
    %                               (x1(x), x1(y), 1, 0, 0, 0;
    %                                0, 0, 0, x1(x), x1(y), 1;
    %                                ...)
    %       Above is continued for other 2 points in x1.^
    % b = (x2) -> 6x1 matrix -> (x2(x); x2(y); ...) 
    %       Above is continued for other 2 points in x2.^
    % Ax = b -> x = A\b -> returns 6x1 matrix (T, c)
    
    % Explanation for above:
    % Knowing x2 = Tx1 + c, T being a 2x2 matrix, and c being a 2x1 matrix
    % We can create the following affine transformation equation:
    % (x', y') = (T11*x + T12*y + c1, T21*x + T22*y + c2)
    % With the above, we can create a system of equations which when
    % written as a matrix, will give us the A shown above.
    % As well, we would have the b being the left side of our system of
    % equations and x being all the unkowns (T and c).
    
    A = zeros(6,6);
    for j = 1:3
        A((j * 2) - 1, :) = [x1(1, j), x1(2, j), 1, 0, 0, 0];
        A(j * 2, :) = [0, 0, 0, x1(1, j), x1(2, j), 1];
    end
    
    b = [x2(1, 1); x2(2, 1); x2(1, 2); x2(2,2); x2(1, 3); x2(2, 3)];
    
    % Using pinv as \ breaks with certain values
    x = pinv(A)*b;
    
    T = [x(1), x(2); x(4), x(5)];
    c = [x(3); x(6)];
    
    inliers = [];
    
    for j = 1:size(closest_matches, 2)
        if ismember(j, rand_sample) == 0
            % Point transformed from image 1
            transformed_1 = (T * f1(1:2, closest_matches(1, j))) + c;
            
            % Point pair image 2
            pair_2 = f2(1:2, closest_matches(2, j));
            
            % Distance from points
            distance = pdist([transformed_1(1), transformed_1(2); 
                              pair_2(1), pair_2(2)], 'euclidean');
            
            if distance < p
                inliers(end + 1) = j;
            end
        end
    end
    
    if (size(inliers, 2) + 3) > size(best_fit, 2)
        for j = 1:3
            inliers(end + 1) = rand_sample(j);
        end
        
        best_fit = inliers;
    end
end

% Compute Optimal Transformation
A = zeros(size(best_fit, 2) * 2, 6);
b = zeros(size(best_fit, 2) * 2, 1);

for i = 1:size(best_fit, 2)
    x1 = f1(1:2, closest_matches(1, best_fit(i)));
    x2 = f2(1:2, closest_matches(2, best_fit(i)));
    
    A((i * 2) - 1, :) = [x1(1), x1(2), 1, 0, 0, 0];
    A(i * 2, :) = [0, 0, 0, x1(1), x1(2), 1];
    
    b((i * 2) - 1) = x2(1);
    b(i * 2) = x2(2);
end

% Using pinv as \ breaks with certain values
x = pinv(A)*b;

% Format x to be square and have last column [zeros(N,1);1] (maketform)
x_formated = [x(1), x(4), 0; ...
              x(2), x(5), 0; ...
              x(3), x(6), 1];
          
% Create Panorama
make_t = maketform('affine', x_formated);

% Mosaic matrix, user-tested size that fits both images
mosaic = cat(2, left_transformed, zeros(2650, 1151, 3));

% User-tested pixels between right image end and mosaic end
upper_bound_y = size(mosaic, 1) - 56;

mosaic(:, :, 1) = setImage(mosaic(:, :, 1), right_image(:, :, 1), upper_bound_y);
mosaic(:, :, 2) = setImage(mosaic(:, :, 2), right_image(:, :, 2), upper_bound_y);
mosaic(:, :, 3) = setImage(mosaic(:, :, 3), right_image(:, :, 3), upper_bound_y);

figure();
imshow(mosaic);

function image = setImage(new_image, old_image, upper_bound_y)
    column_stop = size(new_image, 2) - size(old_image, 2);
    
    row_end = upper_bound_y - size(old_image, 1);
    
    for i = upper_bound_y:-1:row_end + 1
        row_end_count = 5;
        for j = size(new_image, 2):-1:column_stop + 1
            if new_image(i, j) ~= 0 || row_end_count ~= 5
                row_end_count = row_end_count -1;
            end
            
            if row_end_count == 0
                break;
            end
            
            new_image(i, j) = old_image(i - row_end, j - column_stop);
        end
    end
    
    image = new_image;
end
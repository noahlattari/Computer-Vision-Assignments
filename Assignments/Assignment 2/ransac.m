%2.A
run('VLFEATROOT/toolbox/vl_setup')

%2.1 Preprocessing
imgLeft = imread('parliament-left.jpg');
imgLeft = single(rgb2gray(imgLeft));

imgRight = imread('parliament-Right.jpg');
imgRight = single(rgb2gray(imgRight));

imgLeftRGB = imread('parliament-left.jpg');
imgRightRGB = imread('parliament-right.jpg');

%2.2 Detect keypoints and extract descriptors
[fLeft, dLeft] = vl_sift(imgLeft);
[fRight, dRight] = vl_sift(imgRight);

%2.3 Match features
[matches, scores] = vl_ubcmatch(dLeft, dRight);

%2.4 Prune features/Thresholding
%add the k smallest distances from matches into a new matches matrix
[~, cols] = size(matches);
pruned_matches=[];
for i = 1:cols
    if scores(i) < 3500
        pruned_matches(:, size(pruned_matches, 2) + 1) = matches(:, i); %append match to end of pruned_matches
    end
end

%2.5 Robust transformation estimation/RANSAC
%estimate an afine transformation mapping one image to the other.

currentBestModel = [];
cols = size(pruned_matches,2);
for i = 1 : 300 %random number of iterations to find minimum point set. Kosta mentioned "couple hundred"
     y = randsample(cols, 3); %Need 3 random points as there are 6 unknowns for two images (6/2=3).
     y = y.'; 

    %GOAL: Rewrite x2=Tx1+c as Ax=b. T(2x2) and c(2x1) are our unknowns,
    %x1 is a point on the left image, x2 is a point on the right. 
    %A point in an affine map will have the form (x,y) = (ax+by+c,
    %dx+ey+f) where a,b,c,d,e, and f are our 6 unknowns. Since c is only added, we can conclude 
    %T = [a,b ; d,e] and c = [c ; f]
    %Source: https://people.cs.clemson.edu/~dhouse/courses/401/notes/affines-matrices.pdf
    %(page 2).
    
    %Considering we have 3 random points, we can construct a systems of
    %equations.
    %x'0 = ax0+by0+c
    %y'0 = dx0+ey0+f
    %x'1 = ax1+by1+c
    %y'1 = dx1+ey1+f
    %x'2 = ax2+by2+c
    %y'2 = dx2+ey2+f
    
    %A matrix equation to represent this system can be written as folows:
    % A=                   x=   b=
    %[x0, y0, 1, 0, 0, 0   [a   [x'0
    % 0, 0, 0, x0, y0, 1    b    y'0
    % x1, y1, 1, 0, 0, 0    c    x'1
    % 0, 0, 0, x1, y1, 1    d    y'1
    % x2, y2, 1, 0, 0, 0    e    x'2
    % 0, 0, 0, x2, y2, 1 ]  f]   y'2]
    
    %Get our random 3 points in the left and right image
    point1l = (pruned_matches(1,y(1)));  
    point1r = (pruned_matches(2,y(1)));
    point2l = (pruned_matches(1,y(2)));  
    point2r = (pruned_matches(2,y(2)));
    point3l = (pruned_matches(1,y(3)));  
    point3r = (pruned_matches(2,y(3)));

    %Load the associated features for the left image into A (our known)
    A = [fLeft(1, point1l), fLeft(2, point1l), 1, 0, 0, 0; 
         0, 0, 0, fLeft(1, point1l), fLeft(2, point1l), 1;
         fLeft(1, point2l), fLeft(2, point2l), 1, 0, 0, 0;
         0, 0, 0, fLeft(1, point2l), fLeft(2, point2l), 1;
         fLeft(1, point3l), fLeft(2, point3l), 1, 0, 0, 0;
         0, 0, 0, fLeft(1, point3l), fLeft(2, point3l), 1];
    %Load the associated features for the right image into B (our other known)
    B = [fRight(1, point1r);fRight(2, point1r);fRight(1, point2r);fRight(2, point2r);fRight(1, point3r);fRight(2, point3r)];     
    x = A\B; %Estimate out transformation
    T=[x(1), x(2); x(4), x(5)]; %now we know T and c from x, the unknown variables from the original equation.
    c = [x(3); x(6)];
    counter = 1;
    inliers = (cols);
    for j = 1: cols
        x1 = fLeft(1:2, pruned_matches(1,j)); %our left image point
        x2 = T*x1+c; %our transformed point
        realx2 = fRight(1:2, pruned_matches(2,j)); %our point in our original right image
        distance = norm(x2 - realx2); %get distance from the estimated point and the right image point
        if(distance < 5000) %random tested number for distances
            inliers(counter) = j;
            counter = counter + 1;
        end
    end

    [~, inliersCols] = size(inliers);
    [~, bestModelCols] = size(currentBestModel);
    if (inliersCols) > size(bestModelCols, 2) %If we have more inliers than our previous iteration, update currentBestModel
        inliers(size(inliers, 2) + 1) = y(1);
        inliers(size(inliers, 2) + 1) = y(2);   
        inliers(size(inliers, 2) + 1) = y(3);   
        currentBestModel = inliers;
    end
end

%2.6 Compute optimal transformation
A2 = []; B2 = [];
[~, bestModelCols] = size(currentBestModel);
for i = 1:bestModelCols
    point1l = pruned_matches(1, currentBestModel(i));
    point1r = pruned_matches(2, currentBestModel(i));
    %Rebuild our new Ax=b equation variables uses the best model
    A2=[A2; fLeft(1, point1l),fLeft(2, point1l),1,0,0,0;0,0,0,fLeft(1, point1l),fLeft(2, point1l),1]; 
    B2=[B2;fRight(1, point1r);fRight(2, point1r)];
end

%2.7 Create panorama
[rightRows, rightCols] = size(imgRightRGB);
xnew = A2\B2; 
transformation = maketform('affine', [xnew(1),xnew(2),0;xnew(4),xnew(5),0;xnew(3),xnew(6), 1]); %apply an affine transformation with our best model

redChannelLeft = imgLeftRGB(:, :, 1); greenChannelLeft = imgLeftRGB(:, :, 2); blueChannelLeft = imgLeftRGB(:, :, 3); %get our rgb color channels 
redChannelRight = imgRightRGB(:, :, 1); greenChannelRight = imgRightRGB(:, :, 2); blueChannelRight = imgRightRGB(:, :, 3); 

resultRed = fixImage(transformation, redChannelLeft, redChannelRight, 1070, 180, 1430); %Helper to stitch the image with values I trial and error tested lol
resultGreen = fixImage(transformation, greenChannelLeft, greenChannelRight, 1070, 180, 1430);
resultBlue = fixImage(transformation, blueChannelLeft, blueChannelRight, 1070, 180, 1430);

result = cat(3, resultRed, resultGreen, resultBlue); %Combine all our channels for our final image
figure, imshow(result, [0,512]);

function result = fixImage(transformation, leftImage, rightImage, offset, xbound, ybound)
    %Transform the rgb image using the newly estimated transformation
    transformedImage = imtransform(leftImage, transformation);
    %Combine transformed left image with an empty large image
    result = cat(2, transformedImage, zeros([size(transformedImage, 1), offset]));
    rightRows = size(rightImage, 1);
    rightCols = size(rightImage, 2);
    %manually stitch in the empty area with the right image
    result(xbound:end-73, ybound:end) = rightImage(1: rightRows, 1:rightCols);
end
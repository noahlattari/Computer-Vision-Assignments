%2.B
run('VLFEATROOT/toolbox/vl_setup')

imgLeft = imread('Ryerson-left.jpg');
imgLeft = single(rgb2gray(imgLeft));

imgRight = imread('Ryerson-Right.jpg');
imgRight = single(rgb2gray(imgRight));

imgLeftRGB = imread('Ryerson-left.jpg');
imgRightRGB = imread('Ryerson-right.jpg');
% 
% [fLeft, dLeft] = vl_sift(imgLeft);
% [fRight, dRight] = vl_sift(imgRight);
% 
% [matches, scores] = vl_ubcmatch(dLeft, dRight);

[~, cols] = size(matches);
pruned_matches=[];
for i = 1:cols
    if scores(i) < 1500
        pruned_matches(:, size(pruned_matches, 2) + 1) = matches(:, i); %append match to end of pruned_matches
    end
end

currentBestModel = [];
cols = size(pruned_matches,2);

for i = 1 : 300 
     y = randsample(cols, 4); %Now we need 4 points for a homography
     y = y.'; 
     
    point1l = (pruned_matches(1,y(1)));  
    point1r = (pruned_matches(2,y(1)));
    point2l = (pruned_matches(1,y(2)));  
    point2r = (pruned_matches(2,y(2)));
    point3l = (pruned_matches(1,y(3)));  
    point3r = (pruned_matches(2,y(3)));
    point4l = (pruned_matches(1,y(4)));  
    point4r = (pruned_matches(2,y(4)));
    
    %Source:
    %http://6.869.csail.mit.edu/fa12/lectures/lecture13ransac/lecture13ransac.pdf
    %x1 = fLeft(1, point1l)
    %y1 = fLeft(2, point1l)
    %x1' = fRight(1, point1r)
    %y2' = fRight(2, point1r)
    
    A = [fLeft(1, point1l), fLeft(2, point1l), 1, 0, 0, 0, -fRight(1, point1r)*fLeft(1, point1l), -fRight(1, point1r)*fLeft(2, point1l), -fRight(1, point1r); 
         0, 0, 0, fLeft(1, point1l), fLeft(2, point1l), 1, -fRight(2, point1r)*fLeft(1, point1l), -fRight(2, point1r)*fLeft(2, point1l), fRight(2, point1r);
         fLeft(1, point2l), fLeft(2, point2l), 1, 0, 0, 0, -fRight(1, point2r)*fLeft(1, point2l), -fRight(1, point2r)*fLeft(2, point2l), -fRight(1, point2r);
         0, 0, 0, fLeft(1, point2l), fLeft(2, point2l), 1, -fRight(2, point2r)*fLeft(1, point2l), -fRight(2, point2r)*fLeft(2, point2l), fRight(2, point2r);
         fLeft(1, point3l), fLeft(2, point3l), 1, 0, 0, 0, -fRight(1, point3r)*fLeft(1, point3l), -fRight(1, point3r)*fLeft(2, point3l), -fRight(1, point3r);
         0, 0, 0, fLeft(1, point3l), fLeft(2, point3l), 1, -fRight(2, point3r)*fLeft(1, point3l), -fRight(2, point3r)*fLeft(2, point3l), fRight(2, point3r);
         fLeft(1, point4l), fLeft(2, point4l), 1, 0, 0, 0, -fRight(1, point4r)*fLeft(1, point4l), -fRight(1, point4r)*fLeft(2, point4l), -fRight(1, point4r);
         0, 0, 0, fLeft(1, point4l), fLeft(2, point4l), 1, -fRight(2, point4r)*fLeft(1, point4l), -fRight(2, point4r)*fLeft(2, point4l), fRight(2, point4r)];
    [U,S,V]=svd(A);
    H = V(:,end); %the last col of V gives us our 9x1 estimate of the transformation
    H=reshape(H,[3 3]);
    for i= 1:size(H, 1) %Divide by homogenous coordinate
        for j = 1:size(H, 2)
            H(i,j) = H(i,j)/H(3, 3)
        end
    end
    
    counter = 1;
    inliers = (cols);
    for j = 1: cols
        x1 = fLeft(1:2, pruned_matches(1,j)); %our left image point
        x1 = [x1; 1]; %add a dummy value for homogenous coords so we can multiply same dimension vectors
        x2 = H*x1 %our transformed point
        realx2 = fRight(1:2, pruned_matches(2,j)); 
        x2(end) = []; %remove the dummy point so x2 and realx2 are same dimensions
        distance = norm(x2 - realx2); 
        if(distance < 1500) 
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
        inliers(size(inliers, 2) + 1) = y(4);
        currentBestModel = inliers;
    end
end

A2 = []; B2 = [];
[~, bestModelCols] = size(currentBestModel);
for i = 1:bestModelCols %Build our new A based on the best model
    point1l = pruned_matches(1, currentBestModel(i));
    point1r = pruned_matches(2, currentBestModel(i));
    A2=[A2; fLeft(1, point1l), fLeft(2, point1l), 1, 0, 0, 0, -fRight(1, point1r)*fLeft(1, point1l), -fRight(1, point1r)*fLeft(2, point1l), -fRight(1, point1r); 
        0, 0, 0, fLeft(1, point1l), fLeft(2, point1l), 1, -fRight(2, point1r)*fLeft(1, point1l), -fRight(2, point1r)*fLeft(2, point1l), fRight(2, point1r)];
%     B2=[B2;fRight(1, point1r);fRight(2, point1r)];
end

[rightRows, rightCols] = size(imgRightRGB);
[U,S,V]=svd(A2);
H = V(:,end); %estimate our final transformation
H=reshape(H,[3 3]); %force into 3x3 to match original equation
for i= 1:size(H, 1) 
    for j = 1:size(H, 2)
        H(i,j) = H(i,j)/H(3, 3)
    end
end

transformation = maketform('projective', H);

redChannelLeft = imgLeftRGB(:, :, 1); greenChannelLeft = imgLeftRGB(:, :, 2); blueChannelLeft = imgLeftRGB(:, :, 3); redChannelRight = imgRightRGB(:, :, 1); greenChannelRight = imgRightRGB(:, :, 2); blueChannelRight = imgRightRGB(:, :, 3); 

resultRed = fixImage(transformation, redChannelLeft, redChannelRight, 1070, 100, 1430); 
resultGreen = fixImage(transformation, greenChannelLeft, greenChannelRight, 1070, 100, 1430);
resultBlue = fixImage(transformation, blueChannelLeft, blueChannelRight, 1070, 100, 1430);

result = cat(3, resultRed, resultGreen, resultBlue);
result = imrotate(result, 180);
figure, imshow(result, [0,512]);

function result = fixImage(transformation, leftImage, rightImage, offset, xbound, ybound)
    leftImage = flipdim(leftImage, 2);
    transformedImage = imtransform(leftImage, transformation);
    result = cat(2, transformedImage, zeros([size(transformedImage, 1), offset]));
    rightRows = size(rightImage, 1);
    rightCols = size(rightImage, 2);
%     result(xbound:end-72, ybound:end) = rightImage(1: rightRows, 1:rightCols);
    rightImage = imrotate(rightImage, 180);

    result(xbound:xbound+rightRows-1, ybound:ybound-1+rightCols, :) = rightImage;
    
end
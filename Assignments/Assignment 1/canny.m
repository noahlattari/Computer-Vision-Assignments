%2.1
fruitImage = rgb2gray(imread('bowl-of-fruit.jpg'));
outputFruit = MyCanny(fruitImage, 0.5, 15);
figure, imshow(outputFruit);

tonee = rgb2gray(imread('tonee.jpg'));
outputTonee = MyCanny(tonee, 0.5, 15);
figure, imshow(outputTonee);

%2.2
randomFilter = [3 3];
gausFilter_y = fspecial('gaussian', [1 randomFilter(2)], 3); 
%Essentially same idea as 1.5, 2 1D filters, I assumed we would do this outside the function as the function already uses a 2D filter.
gausFilter_x = fspecial('gaussian', [randomFilter(1) 1], 3);
convolved_2 = imfilter(fruitImage, gausFilter_x, 'conv'); 
convolved_3 = imfilter(fruitImage, gausFilter_y', 'conv');


function cannyImg = MyCanny(image, sigma, tau)
    image = double(image);
    
    %1. Filter the image with the x and y derivative Guassian
    gaussKernel = fspecial('gaussian', 3*8, sigma); 
%     sobelKernel = fspecial('sobel');
    g_dx = conv2(gaussKernel, [1 -1]);
    g_dy = conv2(gaussKernel, [1, -1].');
%     derivative = imfilter(gaussKernel, sobelKernel, 'conv');
    image_dy = imfilter(image, g_dy, 'conv');
    image_dx = imfilter(image_dy, g_dx, 'conv');
    
    
    %2. Find gradient magnitude and direction
    image_gmag = sqrt(image_dx.^2 + image_dy.^2);
    image_gdir = atan2(image_dy, image_dx)*180/pi;
    [dirx, diry] = size(image_gdir);
    
    %3. Perform non-maximum surpression
    cannyImg = zeros(dirx, diry);
    
    % Add dummy value to begining and end of matrix so we can start our
    % loop at 2 and end at length-1
    image_gmag(end+1, end+1) = 0;
    image_gmag(1, 1) = 0;
    
    % Loop through our direction matrix to determine which way to look for
    % our local maximums, if we find one set our cannyImg value to 1, else
    % it will stay as 0.
    for r = 2:dirx-1 
        for c = 2:diry-1                      
            currentDirection = image_gdir(r,c);
            currentPixel = image_gmag(r,c);
            if(currentDirection < 0) % convert negative angles to positive
                currentDirection = 360 + currentDirection;
            end
            
            directionInWords = GiveDirection(currentDirection);
            if(directionInWords == "horizontal" && currentPixel > tau)
                if( (currentPixel > image_gmag(r, c+1)) && (currentPixel > image_gmag(r, c-1)) )
                    cannyImg(r,c) = 1;
                end
            elseif(directionInWords == "diagonalRight" && currentPixel > tau)
                if( (currentPixel > image_gmag(r-1, c+1)) && (currentPixel > image_gmag(r+1, c-1)) )
                    cannyImg(r,c) = 1;
                end
            elseif(directionInWords == "vertical" && currentPixel > tau)
                if( (currentPixel > image_gmag(r+1, c)) && (currentPixel > image_gmag(r-1, c)) )
                    cannyImg(r,c) = 1;
                end
            elseif(directionInWords == "diagonalLeft" && image_gmag(r,c) > tau)
                if( (currentPixel > image_gmag(r-1, c-1)) && (currentPixel > image_gmag(r+1, c+1)) )
                    cannyImg(r,c) = 1;
                end
            elseif(directionInWords == "nil")
                    cannyImg(r,c) = 0;
            end
            
        end
    end
%      BW1 = edge(image, 'sobel');
%      figure, imshow(BW1);
end

%Helper method to find the "direction" the angle roughly corelates to so we
%know how to iterate r and c.
function direction = GiveDirection(angle)
%If we divide a unit circle into 16 slices, our range between slice size would
%be 22.5, roughly estimate regions like "horizontal" to be within these
%regions below:

%Example, rougly define "vertical" to be the area in dark red here: https://prnt.sc/10378t9
    if( (angle > 0 && angle < 25) || (angle >= 160 && angle < 205) || (angle >= 340 && angle <=360) ) %third check because in degrees
        direction = "horizontal";
    elseif( (angle >=250 && angle < 295) || ( angle >= 70 && angle < 115))
        direction = "vertical";
    elseif( (angle >= 202.5 && angle < 250) || (angle >= 25 && angle < 70))
        direction = "diagonalRight";
    elseif( (angle >= 115 && angle < 160) || (angle < 340 && angle >= 295) )
        direction = "diagonalLeft";
    else
        direction = "nil";
    end
end
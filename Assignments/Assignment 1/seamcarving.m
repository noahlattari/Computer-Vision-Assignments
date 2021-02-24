%3

ryerson = imread('ryerson.jpg');
tonee2 = imread('tonee.jpg');

ryerson = MySeamCarving(ryerson, 480, 640);
figure, imshow(ryerson);
disp("The new size of ryerson.jpg is:")
disp(size(ryerson));

%***Uncomment for other images****

% ryerson = MySeamCarving(ryerson, 320, 720); %not working for this one ;[
% figure, imshow(ryerson);
% disp(size(ryerson));
% 
% tonee2 = MySeamCarving(tonee2, 200, 200); 
% figure, imshow(tonee2);
% disp(size(tonee2));

function seamImage = MySeamCarving(image, newHeight, newWidth)
    image = double(image);
    test = image(:,:,1);
    [height, width] = size(test);

    for i=1: (width-newWidth)
        image = CarvingHelper(image);
    end
    image = imrotate(image, 90);
    for i=1: (height-newHeight)
        image = CarvingHelper(image);
    end
    image = imrotate(image, -90);
    
   seamImage = image;

end

function out = CarvingHelper(image)
    image = double(image);
    h = fspecial('sobel');
    
    redImg = image(:,:,1); 
    greenImg = image(:,:,2); 
    blueImg = image(:,:,3);
    
    red_dx = imfilter(redImg, h, 'conv');
    red_dy = imfilter(redImg, h', 'conv');
    redEnergy = uint8(round(sqrt(red_dx.^2+red_dy.^2)));
    
    green_dx = imfilter(greenImg, h, 'conv');
    green_dy = imfilter(greenImg, h', 'conv');
    greenEnergy = uint8(round(sqrt(green_dx.^2+green_dy.^2)));
    
    blue_dx = imfilter(blueImg, h, 'conv');
    blue_dy = imfilter(blueImg, h', 'conv');
    blueEnergy = uint8(round(sqrt(blue_dx.^2+blue_dy.^2)));
    
    E = (redEnergy+greenEnergy+blueEnergy);
    
    % b) Create a scoring matrix, M, with spatial image dimensions matching those of the input image
    M = zeros(size(E));

    % c)Set the values of the first row of the scoring matrix, M, to match those of the energy image, E.
    M(1 ,:, :) = E(1, :, :);
    [rows, cols] = size(E);
    
    % d) Set the values of every entry in the scoring matrix to the energy value at that position and the minimum value in 
    %    any of the neighbouring cells above it in the seam
    first = 1;
    for r = 2: rows % row 1 is already populated with E row 1
        for c=1: cols 
            if(r == rows)
                  
                M(r, c) = E(r, c) + min(M(r,c), M(r-1,c));
            else
                M(r, c) = E(r, c) + min([M(r,c), M(r-1,c), M(r+1,c)]); %cant call min on 3 params, put in array first
            end   
        end
    end
   
    % e) Find the minimum value in the bottom row of the scoring matrix. The corresponding position of the minimal value is the bottom of the optimal seam.
    [minimum, i] = min(M(rows, :));
    if(i ~= 1)        
        temp = image(rows, 1:i);
        temp2 = circshift(temp, 1);
        image(rows, 1:i) = temp2;
    end
   	for r = rows-1: -1:1
        if (i == 1)
            [minimum, i] = min(M(r, i:i+1));
        elseif (i == cols)
            [minimum, i] = min(M(r, i-1:i));
        else
            [minimum, i] = min(M(r,i-1:i+1));
        end
        if(i ~= 1)
            temp = image(r, 1:i);
            temp2 = circshift(temp, 1);
            image(r, 1:i) = temp2;
        end
    end
    image(:, 1, :) = [];
    out = uint8(image);
 end






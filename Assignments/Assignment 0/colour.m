img = imread('./images/baboon.tiff');
%imshow(img, [0,512]); %Original image
%1=red, 2=green, 3=blue
red = img(:, :, 1);
green = img(:, :, 2);
blue = img(:, :,3);

img = cat(3, blue, green, red); 
figure, imshow(img, [0,512]);

img_g = img(:, :, 2);
figure, imshow(img_g, [0,512]);

img_r = img(:, :, 1);
figure, imshow(img_g, [0,512]);

img = rgb2gray(img);
figure, imshow(img, [0,512]);


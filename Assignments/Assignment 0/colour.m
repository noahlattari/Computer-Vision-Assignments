% Question 2

%a)
img = imread('./images/baboon.tiff');

%b)
red = img(:, :, 1);
green = img(:, :, 2);
blue = img(:, :,3);

img = cat(3, blue, green, red); 
figure, imshow(img, [0,512]);

%c)
img_g = double(img(:, :, 2));
figure, imshow(img_g, [0,512]);

%d)
img_r = img(:, :, 1);
figure, imshow(img_g, [0,512]);

%e)
img = rgb2gray(img);
figure, imshow(img, [0,512]);


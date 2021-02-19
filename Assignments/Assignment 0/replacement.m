% Question 3

img2 = rgb2gray(imread('./images/splash.tiff'));

box = img_g(206:306, 206:306);
img2(206:306, 206:306) = box;

figure, imshow(img2, [0,512]);

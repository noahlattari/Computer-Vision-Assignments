img2 = rgb2gray(imread('./images/splash.tiff'));
%figure, imshow(img2, [0,512]);
%figure, imshow(img_g, [0,512]);

box = img_g(206:306, 206:306);
img2(206:306, 206:306) = box;

figure, imshow(img2, [0,512]);

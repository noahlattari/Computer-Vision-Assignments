% Question 5

%For standard deviation, I just used the standard deviation of the pixels
%(47.7).
img_color = imread('./images/baboon.tiff');

standard_deviation = std(double((img_color(:))));
gnoise = double(img_color)+randn(size(img_color))*standard_deviation;

figure, imshow(gnoise, [0,512]);
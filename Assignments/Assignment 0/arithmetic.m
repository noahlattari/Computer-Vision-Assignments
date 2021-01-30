%Question 4.

%a)
min_value = min(img_g(:)); %(:) converts the 2d matrix into a vector we can call min/max on.
disp(min_value); % The minimum of all pixels is 0.

max_value = max(img_g(:));
disp(max_value); %The maximum of all pixels is 236.

% Manual calculation of mean:
% sum_of_all_terms = sum(img_g(:));
% number_of_pixels = length(img_g(:)); % Will equal 512x512 (our image dimnensions)
% mean = sum_of_all_terms/number_of_pixels;
% disp("The mean is: " + mean);

image_mean = mean(double((img_g(:))));
disp("The mean is: " + image_mean);
standard_deviation = std(double((img_g(:)))); % std function needs single or doubles.
disp("The sd is: " + standard_deviation);

% I computed these by running built-in matlab functions mean() & std() on a
% vector that represents our img_g pixels, they can also be computed
% manually as shown in the comments above.

%b)

calculated_img_g = ((((img_g - image_mean)/standard_deviation)*10) + image_mean);
figure, imshow(calculated_img_g, [0,512]);

%c)

img_g_shifted = circshift(img_g, -2, 2);
% Shift columns two positions circularly to avoid using for loop (helps
% with elements near the begining and end of matrix).
figure, imshow(img_g_shifted, [0,512]);

%d)
img_g_subtracted = double(img_g_shifted) - double(img_g);
figure, imshow(img_g_subtracted, [0,512]); % horrifying to say the least

%e)

img_g_flipped = img_g(:, end:-1:1);
figure, imshow(img_g_flipped, [0,512]); %Access columns in reverse

%f)
img_g_inverted = max_value - img_g;
% A pixel of value 0 would become 236 (our max pixel) - 0 = 236.
% A pixel of value 235 would become 236 - 235 = 1. 
figure, imshow(img_g_inverted, [0,512]);


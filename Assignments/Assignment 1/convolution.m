%1.1
result = [0 5 0 0 0 0 0 0 0 0;
          0 0 0 0 0 0 0 0 0 0;
          0 -7 2 8 -1 2 -1 -3 0 0;
          0 0 1 1 0 0 -1 -1 0 0;
          0 0 3 1 -2 4 -1 -7 0 0;
          0 0 -1 -1 0 0 1 -1 0 0;
          0 0 1 2 2 2 -3 -4 0 0;
          0 0 0 0 0 0 0 0 0 0;
          0 0 0 0 0 0 0 0 0 0];
disp(result); % I decided to use disp in place of fprinf as it formatted nicely by default.

%1.2
leftMatrix = [-5 0 0 0 0 0 0 0 0 0; 
               0 0 0 0 0 0 0 0 0 0; 
               0 0 -7 2 1 1 3 0 0 0; 
               0 0 0 1 1 1 1 0 0 0;
               0 0 0 3 1 1 5 0 0 0;
               0 0 0 -1 -1 -1 -1 0 0 0;
               0 0 0 1 2 3 4 0 0 0;
               0 0 0 0 0 0 0 0 0 0;
               0 0 0 0 0 0 0 0 0 0];

h = fspecial('sobel');
im1_dx = imfilter(double(leftMatrix), h, 'conv');
im1_dy = imfilter(double(leftMatrix), h', 'conv');
res = (sqrt(im1_dx.^2 + im1_dy.^2));

disp('Pixel at (2,3) is: ');
disp(res(3,4));

disp('Pixel at (4,3) is: ');
disp(res(5,4));

disp('Pixel at (4,6) is: ');
disp(res(5,7));

%1.3

inputFilter = [-1, 0, 1];
res = MyConv(leftMatrix, inputFilter); %function at end of file.
disp(res);

%1.4
x1 = randi([10, 10], 13);
gausFilter = fspecial('gaussian', 13, 2);
testInput1 = imfilter(x1, gausFilter, 'conv', 0);

testInput2 = MyConv(x1, gausFilter);

difference = testInput1 - testInput2;   
figure, imshow(abs(difference));

%1.5
readImage = im2double(imread('eye.png'));

%figure, imshow(readImage)
sigma = 8;
gausFilter2 = fspecial('gaussian', 3*sigma, 8); %three sigma rule


tic
convolvedImage1 = imfilter(readImage, gausFilter2, 'conv'); %2D Filter
toc

gausFilter_x = fspecial('gaussian', [1, 3*sigma], 8); %1D Filters
gausFilter_y = fspecial('gaussian', [sigma*8, 1], 8); 

tic
convolvedImage2 = imfilter(imfilter(readImage,gausFilter_x), gausFilter_y, 'conv');
toc

%figure, imshow(convolvedImage2);
disp("I noticed that the convolution with the two 1-D filters on average take longer to process");

function convoluted = MyConv(image, filter)
    [irows, icols] = size(image);
    [krows, kcols] = size(filter);
    convoluted = zeros(irows, icols); % pre fill result with 0s
    filter = fliplr(flipud(filter)); %Flip filter left to right and up to down
    
    for ir = 1 : irows
        for ic = 1 : icols
            counter = 0;          
            for kr = 1 : krows
                for kc = 1 : kcols
                    currentRow = (ir - kr) + 1; %Get our "real" row and col for the sliding window.
                    currentCol = (ic - kc) + 1;                   
                     if (currentRow > 0) && (currentCol > 0)
                       counter = (image(currentRow, currentCol) * filter(kr, kc)) + counter;    
                     elseif (currentRow == 0 || currentCol == 0) % if we are out of bounds just set our accum to 0
                         counter = 0;
                     else
                       counter = 0;
                    end
                end
            end
            bounds = ic - floor((kcols / 2));
            if (bounds > 0)
                convoluted(ir, bounds) = counter ;
            end
        end
    end
end

%I referened a psuedocode algorithm pretty closely for this as I was a
%little lost, the source is slide 3:
%https://www.cs.auckland.ac.nz/courses/compsci373s1c/PatricesLectures/Convolution_1up.pdf
%Please let me know in the future if this is not allowed. I noticed that it
%works  for question 1 (it yields the same result I got by hand),
%but works oddly sometimes for other results.
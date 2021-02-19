%1.1
leftMatrix = [-5 0 0 0 0 0 0 0 0 0; 
               0 0 0 0 0 0 0 0 0 0; 
               0 0 -7 2 1 1 3 0 0 0; 
               0 0 0 1 1 1 1 0 0 0;
               0 0 0 3 1 1 5 0 0 0;
               0 0 0 -1 -1 -1 -1 0 0 0;
               0 0 0 1 2 3 4 0 0 0;
               0 0 0 0 0 0 0 0 0 0;
               0 0 0 0 0 0 0 0 0 0];

result = [0 5 0 0 0 0 0 0 0 0;
          0 0 0 0 0 0 0 0 0 0;
          0 -7 2 8 -1 2 -1 -3 0 0;
          0 0 1 1 0 0 -1 -1 0 0;
          0 0 3 1 -2 4 -1 -7 0 0;
          0 0 -1 -1 0 0 1 1 0 0;
          0 0 1 2 2 2 -3 -4 0 0;
          0 0 0 0 0 0 0 0 0 0;
          0 0 0 0 0 0 0 0 0 0];
% disp(result);

%1.2

h = fspecial('sobel');
im1_dy = imfilter(double(leftMatrix), h, 'conv');
im1_dx = imfilter(double(leftMatrix), h', 'conv');
res = (sqrt(im1_dx.^2 + im1_dy.^2));

disp('Pixel at (2,3) is: ');
disp(res(3,4));

disp('Pixel at (4,3) is: ');
disp(res(5,4));

disp('Pixel at (4,6) is: ');
disp(res(5,7)); %
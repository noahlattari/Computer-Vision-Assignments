%Question 1.1 & 1.2

synth_1 = imread("./synth/synth_1.png");
synth_0 = imread("./synth/synth_0.png");

sphere_1 = imread("./sphere/sphere_1.png");
sphere_0 = imread("./sphere/sphere_0.png");
[u, v, bmap] = myFlow(sphere_1 , sphere_0 , 10, 0.5);
figure,imshow(flowToColor(cat(3, u, v)));

bt_1 = imread("./corridor/bt_1.png");
bt_2 = imread("./corridor/bt_0.png");

disp("After playing around with the window size, I noticed that when I make the");
disp("the window size smaller I can more easily tell where there is movement");
disp("On the contrary, when the window size is bigger I can see more color and");
disp("overall more of the image, but the motion is harder to see");

%Question 1.3

function [u, v, bmap] = myFlow(img1, img2, windowLength, tau)
    img1 = mat2gray(rgb2gray(img1));
    img2 = mat2gray(rgb2gray(img2));
    
    %use the five-point derivative of Gaussian convolution filter (1/12)*[-1 8 0 -8 1]
    
    %Use this filter for spatial derivatives 
    gauss_filter = (1/12)*[-1 8 0 -8 1];
    gauss_filter = flip(gauss_filter);
    
    I_x = conv2(img1, gauss_filter, 'same');
    I_y = conv2(img1, gauss_filter', 'same');
    
    %Find the temporal derivative for difference of both immages using og
    %gauss
    gaussian = fspecial('gaussian',3,1);
    
    %Setup our equation from the lecture (A*v=B) where A and B are our
    %knowns, and v is a 2x1 vector of unknowns (u and v) 
    I_xsq = conv2(I_x .* I_x, ones(windowLength), 'same');
    I_ysq = conv2(I_y .* I_y, ones(windowLength), 'same');
    I_xy = conv2(I_x .* I_y, ones(windowLength), 'same');
    
    I_t = conv2(img2, gaussian, 'same') - conv2(img1, gaussian, 'same');
    I_xt = conv2(I_x .*I_t, ones(windowLength), 'same');
    I_yt = conv2(I_y .*I_t, ones(windowLength), 'same');
    
    
    %prefill variables to 0 to avoid needed else condition
    u = zeros(size(img1));
    v = zeros(size(img1));
    bmap = zeros(size(img1));
    
    %size
    [rows, cols] = size(img1);
    
    for i = 2: rows-1
        for j = 2:cols-1
            %"Compute spacial derivatives"
            A = [I_xsq(i,j) I_xy(i,j);
                 I_xy(i,j) I_ysq(i,j)];             
            %"when their smallest eigenvalue is not zero, or in practice,
            %greater than some threshold"
            if(min(eig(A)) ~= 0 || min(eig(A)) > tau)
                %"Compute temporal derivative"
                %I only compute the temporal when the if is met to avoid
                %computing it for every single iteration #efficiency 
                B = -[I_xt(i,j); I_yt(i,j)];
                estimate = pinv(A)*B;
                bmap(i,j) = 1;
                u(i,j) = estimate(1);
                v(i,j) = estimate(2);
            end
            %"At image points where the flow is not computable, set the flow value to zero".
            %this is not needed becauuse u v and bmap are prefilled with 0s
        end
    end
end
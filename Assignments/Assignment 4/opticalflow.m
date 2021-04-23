%SYNTH
%load images, convert to double.grayscale 
synth_1 = double(im2gray(imread("./synth/synth_1.png")));
synth_0 = double(im2gray(imread("./synth/synth_0.png")));

%get our new vertical and horizontal from myFlow
[u, v, bmap] = myFlow(synth_0 , synth_1 , 10, 0.5); %tested sizes until they looked ok
figure,imshow(flowToColor(cat(3, u, v)), []); %combine into new image for flowtocolor

%warp our image back
warped = myWarp(synth_1, u, v);
diff = abs((synth_0) - (warped)); %compare absolute difference between warped image and original
figure, imshow(diff, []);
compareImages(warped, synth_0, 2);


%SPHERE
sphere_1 = double(rgb2gray(imread("./sphere/sphere_1.png")));
sphere_0 = double(rgb2gray(imread("./sphere/sphere_0.png")));

[u, v, bmap] = myFlow(sphere_0 , sphere_1 , 5, 0.001);
figure,imshow(flowToColor(cat(3, u, v)), []);

warped1 = myWarp(sphere_1, u, v);
diff1 = abs(double(sphere_0) - double(warped1));
figure, imshow(diff1, []);
compareImages(warped1, sphere_0, 2);


%CORRIDOR
bt_1 = double(im2gray(imread("./corridor/bt_1.png")));
bt_0 = double(im2gray(imread("./corridor/bt_0.png")));

[u, v, bmap] = myFlow(bt_0 , bt_1 , 35, 0.001);
figure,imshow(flowToColor(cat(3, u, v)), []); %not sure why it looks like that, I tried playing around with many values with no luck, at least it looks cool

warped2 = myWarp(bt_1, u, v);
diff2 = abs(bt_0 - warped2);
figure, imshow(diff2, []);
compareImages(warped2, bt_0, 2);


disp("After playing around with the window size, I noticed that when I make the");
disp("the window size smaller I can more easily tell where there is movement");
disp("On the contrary, when the window size is bigger I can see more color and");
disp("overall more of the image, but the motion is harder to see");

function compareImages(img1, img2, iters)
    %helper function to compare the images
    for i = 1:iters
        figure, imshow(img1, []);
        figure, imshow(img2, []);        
    end

end

function warped = myWarp(img2, u, v)    
    %If the images are identical except for a translation and the estimated flow is correct then the warped img2 will be identical to img1
    %Use MATLAB’s functions interp2 (try bicubic and bilinear interpolation) and meshgrid.
    
    [row,col] = meshgrid(1:size(img2, 1), 1:size(img2, 2));
    warped = (interp2(img2, u+row, v+col)); %defaults to linear
    %subtracting them makes more sense but the images look better with addition
    
    %remove all NaNs
    warped(isnan(warped))=0;
    
    %check to make sure there are no NaNs
    x = (ismember(NaN, warped));
    if(x~=0)
        disp("NaN found");
    end

end

function [u, v, bmap] = myFlow(img1, img2, windowLength, tau)
    %Use this filter for spatial derivatives 
    gauss_filter = (1/12)*[-1 8 0 -8 1];
    gauss_filter = flip(gauss_filter); %flip it 
    gaussian = fspecial('gaussian',3,1); %grab a vanilla gauss filter
    
    %Setup our equation from the lecture (A*v=B) where A(2x2) and B(2x1) are our
    %knowns, and v(2x1) vector of unknowns (u and v) 
    x = conv2(img1, gauss_filter, 'same');
    y = conv2(img1, gauss_filter', 'same');

    xsq = conv2(x.*x, ones(windowLength), 'same');
    ysq = conv2(y.*y, ones(windowLength), 'same');
    xy = conv2(x.*y, ones(windowLength), 'same');
    
    %Find the temporal derivative for difference of both immages using og
    %gauss filter
    timg2 = conv2(img2, gaussian, 'same');
    timg1 = conv2(img1, gaussian, 'same');
    t = timg1-timg2;
    xt = conv2(x.*t, ones(windowLength), 'same');
    yt = conv2(y.*t, ones(windowLength), 'same');
    
    %prefill variables to 0 to avoid needed else condition
    u = zeros(size(img1));
    v = zeros(size(img1));
    bmap = zeros(size(img1));
    
    %size
    [rows, cols] = size(img1);
    
    for row = 2:rows-1
        for col = 2:cols-1
            %"Compute spacial derivatives"
            A = [xsq(row,col) xy(row,col);
                 xy(row,col) ysq(row,col)];             
            %"when their smallest eigenvalue is not zero, or in practice,
            %greater than some threshold"
            if(min(eig(A)) ~= 0 || min(eig(A)) > tau)
                %"Compute temporal derivative"
                %I only compute the temporal when the if is met to avoid
                %computing it for every single iteration #efficiency 
                B = -[xt(row,col); yt(row,col)];
                estimate = pinv(A)*B; %A\B wasn't working, weird errors
                bmap(row,col) = 1;
                u(row,col) = estimate(1);
                v(row,col) = estimate(2);
            end
            %"At image points where the flow is not computable, set the flow value to zero".
            %this is not needed becauuse u v and bmap are prefilled with 0s
        end
    end
end
%~~ Kosta lecture code for reference ~~
% x=[1:20]';
% m = 2;
% b = 5;
% y=m*x+b;
% y = y + randn(size(x));
% A = [x ones(size(x))];
% mb_estimate = A\y;

%1.1
alpha = 10;
beta = 12;
gamma = 15;

x = rand([500 1]) - 0.5; %from matlab break
y = rand([500 1]) - 0.5;
z = alpha.*x + beta.*y + gamma;
figure, scatter3(x,y,z);
rotate3d;
%noise adding
z = z + (randn(size(x)) + randn(size(y)));

%1.2
%rewrite z = alphax+betay+gamma as Ax=b where x is the vector of unknowns

temp = ones(size(x)); % to get gamma vector since gamma is not multiplied by anything, just set to ones
A = [x,y,temp];

%estimate x, our unknowns 
x = A\z;

%1.3
alphaDiff = abs(x(1) - alpha);
disp("The error in the alpha estimate is: " + alphaDiff);
betaDiff = abs(x(2) - beta);
disp("The error in the beta estimate is: " + betaDiff);
gammaDiff = abs(x(3) - gamma);
disp("The error in the gamma estimate is: " + gammaDiff);
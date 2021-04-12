% you might want to have as many negative examples as positive examples
n_have = numel(dir('cropped_training_images_notfaces/*.jpg'));
n_want = numel(dir('cropped_training_images_faces/*.jpg'));

imageDir = 'images_notfaces';
imageList = dir(sprintf('%s/*.jpg',imageDir));
nImages = length(imageList);

new_imageDir = 'cropped_training_images_notfaces';
mkdir(new_imageDir);

dim = 36;

while n_have < n_want
    % generate random 36x36 crops from the non-face images
    rand_image_num = randi([1 nImages]);
    
    image = imread(strcat(imageDir, '/', imageList(rand_image_num).name));
    
    row = randi([1 (size(image, 1) - 36)]);
    col = randi([1 (size(image, 2) - 36)]);
    
    new_image = rgb2gray(image(row:row + 36, col:col + 36, :));
    
    imwrite(new_image, strcat('cropped_training_images_notfaces/', string(n_have + 1), '.jpg'));
    
    n_have = n_have + 1;
end
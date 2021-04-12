% Summary of approach
fprintf('As a summary of our approach, we tried out multiple different scales.\n');
fprintf('We updated the scales to see how our precision gets affected.\n');
fprintf('When a certain scale range yielded better precision, we changed the code accordingly.\n');
fprintf('We also implemented non-maximum surpression which included the use of thresholding.\n');
fprintf('Thresholding allowed us to set a minimum confidence value to get rid of lower confidence face guesses.\n');

fprintf('Our best precision so far was: \n');
figure('Name', 'Average Precision');
imshow('average_precision.png');
pause;

fprintf('Our false positives were: .\n');
figure('Name', 'False Positives');
imshow('false_positives.jpg');
pause;

fprintf('For class.jpg, our results were .\n');
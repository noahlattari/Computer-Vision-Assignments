% Best accuracy on validation set
fprintf('Classifier performance on validation set features:\n')
fprintf('accuracy: 0.993\n');
fprintf('true  positive rate: 0.495\n');
fprintf('false positive rate: 0.002\n');
fprintf('true  negative rate: 0.498\n');
fprintf('false negative rate: 0.005\n');

fprintf('Above are the results for the record my_svm.mat.\n');

% Summary of approach
fprintf('The approach used was to first get the features for all face and non-face images.\n');
fprintf('Then, after storing the features, when loading it in train_svm, split the features into\n');
fprintf('validation and training sets. We then trained the SVM with the training set and had the above\n');
fprintf('results when compared to the validation set.\n');
fprintf('To improve performance, we tweaked the lambda value to be significantly smaller,\n');
fprintf('we found that a lambda value at 0.0001 produced optimal results for the model.\n');
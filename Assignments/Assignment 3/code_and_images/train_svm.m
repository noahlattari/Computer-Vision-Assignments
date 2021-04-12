run('../vlfeat-0.9.21/toolbox/vl_setup')
load('pos_neg_feats.mat')

% Split Training/Validation sets
pos_training_count = round(0.8 * pos_nImages);
neg_training_count = round(0.8 * neg_nImages);

pos_feats_train = pos_feats(1:pos_training_count, :);
neg_feats_train = neg_feats(1:neg_training_count, :);

pos_feats_valid = pos_feats(pos_training_count + 1:end, :);
neg_feats_valid = neg_feats(neg_training_count + 1:end, :);

feats_train = cat(1, pos_feats_train, neg_feats_train);
labels_train = cat(1, ones(pos_training_count, 1), -1 * ones(neg_training_count, 1));

feats_valid = cat(1, pos_feats_valid, neg_feats_valid);
labels_valid = cat(1, ones(pos_nImages - pos_training_count, 1), ...
    -1 * ones(neg_nImages - neg_training_count, 1));

lambda = 0.0001;
[w, b] = vl_svmtrain(feats_train', labels_train', lambda);

fprintf('Classifier performance on training set features:\n')
confidences_train = [pos_feats_train; neg_feats_train] * w + b;
[tp_rate_train, fp_rate_train, tn_rate_train, fn_rate_train] = ...
    report_accuracy(confidences_train, labels_train);

fprintf('Classifier performance on validation set features:\n')
confidences_valid = [pos_feats_valid; neg_feats_valid] * w + b;
[tp_rate_valid, fp_rate_valid, tn_rate_valid, fn_rate_valid] = ...
    report_accuracy(confidences_valid, labels_valid);

save('my_svm.mat', 'w', 'b')

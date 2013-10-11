function [ recRate, confusionMat, scores, liblinearModel ] = liblinearTrainTest( hists_train, labels_train, hists_test, labels_test, config )
%LIBLINEARTRAINTEST Compute recognition rates using liblinear svm

    liblinearModel = liblinearTrain(hists_train, labels_train, config);
    [recRate, confusionMat, scores] = liblinearTest(hists_test, labels_test, liblinearModel, config);
end


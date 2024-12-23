"""
    This script contains functions to evaluate the performance of classifiers, including confusion matrices and several metrics for binary and multi-class classification problems. It also includes functions to preprocess data for cross-validation.

    The script is divided in 2 sections:
    1. Single Classifier Evaluation: Functions to evaluate the performance of a single classifier for binary and multi-class classification problems.
    2. Multi-class Classifier Evaluation: Functions to evaluate the performance of a multi-class classifier for binary and multi-class classification problems.
"""


using Random;
using Statistics;
using Plots;

""" 1. SINGLE CLASSIFIER EVALUATION """

function classifyOutputs(outputs::AbstractArray{<:Real,2}; 
    threshold::Real=0.5) 
    """
    This function transforms the real-valued outputs of a classifier into boolean values, based on a threshold in the case of binary classification, or by selecting the maximum value in each row in the case of multi-class classification.
    
    Parameters:
        - (!)outputs: a matrix with the real-valued outputs of a classifier. Each row corresponds to an instance, and each column corresponds to a class. Thii array is modified with the boolean values.
        - threshold: a real number between 0 and 1 that defines the threshold for binary classification.
    
    Returns:
        - A boolean matrix with the same shape as the input array, where each row has a single 'true' value corresponding to the class with the highest output value.
    """
    
    # Check that the number of columns is not 2, as for 2 classes there will be a single column and for three or more classes there will three or more columns.
    numOutputs = size(outputs, 2);
    @assert(numOutputs!=2)

    # If the number of columns is 1, we apply the threshold.
    if numOutputs==1
        return outputs.>=threshold;
    # If not, we find the maximum value in each row and set it to true, while the rest are set to false.
    else
        (_,indicesMaxEachInstance) = findmax(outputs, dims=2);
        outputs = falses(size(outputs));
        outputs[indicesMaxEachInstance] .= true;
        @assert(all(sum(outputs, dims=2).==1));
        return outputs;
    end;

end

classifyOutputs!(outputs::AbstractArray{<:Real,1}; threshold::Real=0.5) = classifyOutputs(outputs, threshold=threshold);


function accuracy(outputs::AbstractArray{Bool,1}, targets::AbstractArray{Bool,1}) 
    """
    This function calculates the accuracy of a binary classifier given its boolean outputs and the target values.
    
    Parameters:
        - outputs: a 1D boolean array with the outputs of the classifier.
        - targets: a 1D boolean array with the target values.
    
    Returns:
        - A real number between 0 and 1 with the accuracy of the classifier.
    """

    @assert(length(outputs)==length(targets));
    return mean(outputs.==targets);

end;

function accuracy(outputs::AbstractArray{Bool,2}, targets::AbstractArray{Bool,2})
    """
    This function calculates the total accuracy of a multi-class classifier given its boolean outputs and the target values.
    
    Parameters:
        - outputs: a boolean matrix with the outputs of the classifier.
        - targets: a boolean matrix with the target values.
    
    Returns:
        - A real number between 0 and 1 with the total accuracy of the classifier.
    """
    
    @assert(all(size(outputs).==size(targets)));
    if (size(targets,2)==1)
        return accuracy(outputs[:,1], targets[:,1]);
    else
        return mean(all(targets .== outputs, dims=2));
    end;

end;

function accuracy(outputs::AbstractArray{<:Real,1}, targets::AbstractArray{Bool,1};      
    threshold::Real=0.5)

    """
    This function calculates the accuracy of a binary classifier given its real-valued outputs and the target values.
    
    Parameters:
        - outputs: a 1D real-valued array with the outputs of the classifier.
        - targets: a 1D boolean array with the target values.
        - threshold: a real number between 0 and 1 that defines the threshold for binary classification.
    
    Returns:
        - A real number between 0 and 1 with the accuracy of the classifier.
    """
    
    accuracy(outputs.>=threshold, targets);

end;

function accuracy(outputs::AbstractArray{<:Real,2}, targets::AbstractArray{Bool,2};
    threshold::Real=0.5)
    """
    This function calculates the total accuracy of a multi-class classifier given its real-valued outputs and the target values.
    
    Parameters:
        - outputs: a real-valued matrix with the outputs of the classifier.
        - targets: a boolean matrix with the target values.
        - threshold: a real number between 0 and 1 that defines the threshold for binary classification.
    
    Returns:
        - A real number between 0 and 1 with the total accuracy of the classifier.
    """
    
    @assert(all(size(outputs).==size(targets)));
    if (size(targets,2)==1)
        return accuracy(outputs[:,1], targets[:,1]);
    else
        return accuracy(classifyOutputs(outputs; threshold=threshold), targets);
    end;

end;   

function computeMetrics(tp::Int, tn::Int, fp::Int, fn::Int)
    """
    This function calculates several metrics of a binary classifier given the number of true positives, true negatives, false positives, and false negatives.
    
    Parameters:
        - tp: an integer with the number of true positives.
        - tn: an integer with the number of true negatives.
        - fp: an integer with the number of false positives.
        - fn: an integer with the number of false negatives.
    
    Returns:
        - A dictionary with the following metrics:
            - accuracy: a real number between 0 and 1 with the accuracy of the classifier.
            - error_rate: a real number between 0 and 1 with the error rate of the classifier.
            - recall: a real number between 0 and 1 with the recall of the classifier.
            - precision: a real number between 0 and 1 with the precision of the classifier.
            - specifity: a real number between 0 and 1 with the specifity of the classifier.
            - negative_predictive_value: a real number between 0 and 1 with the negative predictive value of the classifier.
            - f1_score: a real number between 0 and 1 with the F-score of the classifier.
    """


    # Calculate the metrics
    total = tp + tn + fp + fn
    accuracy = (tp + tn) / total
    error_rate = 1 - accuracy

    # For the rest of the metrics, we need to check if the denominator is 0
    if tn == total
        recall = 1
        precision = 1
        specifity = 1
        negative_predictive_value = 1
        f1_score = 1
    elseif tp == total
        specifity = 1
        negative_predictive_value = 1
        recall = 1
        precision = 1
        f1_score = 1
    else
        if tp + fn == 0
            recall = 0
        else
            recall = tp / (tp + fn)
        end
        if tn + fp == 0
            specifity = 0
        else
            specifity = tn / (tn + fp)
        end
        if tp + fp == 0
            precision = 0
        else
            precision = tp / (tp + fp)
        end
        if tn + fn == 0
            negative_predictive_value = 0
        else
            negative_predictive_value = tn / (tn + fn)
        end
        if precision + recall == 0
            f1_score = 0
        else
            f1_score = 2 * (precision * recall) / (precision + recall)
        end
    end

    return Dict{Symbol, Any}(
        :accuracy => accuracy,
        :error_rate => error_rate,
        :recall => recall,
        :precision => precision,
        :specificity => specifity,
        :negative_predictive_value => negative_predictive_value,
        :f1_score => f1_score
    )
end


function confusionMatrix(outputs::AbstractArray{Bool,1}, targets::AbstractArray{Bool,1})
    """
    This function calculates the confusion matrix and several metrics of a binary classifier given its boolean outputs and the target values.

    Parameters:
        - outputs: a 1D boolean array with the outputs of the classifier.
        - targets: a 1D boolean array with the target values.

    Returns:
        - A dictionary with the following metrics:
            - accuracy: a real number between 0 and 1 with the accuracy of the classifier.
            - error_rate: a real number between 0 and 1 with the error rate of the classifier.
            - recall: a real number between 0 and 1 with the recall of the classifier.
            - precision: a real number between 0 and 1 with the precision of the classifier.
            - specifity: a real number between 0 and 1 with the specifity of the classifier.
            - negative_predictive_value: a real number between 0 and 1 with the negative predictive value of the classifier.
            - f1_score: a real number between 0 and 1 with the F-score of the classifier.
            - confusion_matrix: a matrix with the confusion matrix of the classifier.
    """
    
    TP = sum(outputs .& targets)
    TN = sum(.!outputs .& .!targets)
    FP = sum(outputs .& .!targets)
    FN = sum(.!outputs .& targets)

    metrics = computeMetrics(TP, TN, FP, FN)
    confusion_matrix = [TP FN; FP TN]   
    metrics[:confusion_matrix] = confusion_matrix

    return metrics

end

function confusionMatrix(outputs::AbstractArray{<:Real,1}, targets::AbstractArray{Bool,1}; threshold::Real = 0.5)
    """
    This function calculates the confusion matrix and several metrics of a binary classifier given its real-valued outputs and the target values.
    
    Parameters:
        - outputs: a 1D real-valued array with the outputs of the classifier.
        - targets: a 1D boolean array with the target values.
        - threshold: a real number between 0 and 1 that defines the threshold for binary classification.

    Returns:
        - A dictionary with the following metrics:
            - accuracy: a real number between 0 and 1 with the accuracy of the classifier.
            - error_rate: a real number between 0 and 1 with the error rate of the classifier.
            - recall: a real number between 0 and 1 with the recall of the classifier.
            - precision: a real number between 0 and 1 with the precision of the classifier.
            - specifity: a real number between 0 and 1 with the specifity of the classifier.
            - negative_predictive_value: a real number between 0 and 1 with the negative predictive value of the classifier.
            - f1_score: a real number between 0 and 1 with the F-score of the classifier.
            - confusion_matrix: a matrix with the confusion matrix of the classifier.
    """

    # Convert real-valued outputs to boolean based on the threshold
    binary_outputs = outputs .>= threshold
    
    # Call the original confusionMatrix function with boolean outputs
    return confusionMatrix(binary_outputs, targets)

end

function printMetrics(metrics::Dict)
    """
    This function prints the metrics of a binary classifier given a dictionary with the metrics.
    
    Parameters:
        - metrics: a dictionary with the metrics of the classifier.
    
    Returns:
        - Nothing
    """
    
    println("Accuracy: $(metrics[:accuracy])")
    println("Error Rate: $(metrics[:error_rate])")
    println("Sensitivity (Recall): $(metrics[:recall])")
    println("Specificity: $(metrics[:specificity])")
    println("Positive Predictive Value (Precision): $(metrics[:precision])")
    println("Negative Predictive Value: $(metrics[:negative_predictive_value])")
    println("F-score: $(metrics[:f1_score])")

    heatmap(metrics[:confusion_matrix], c=:Greens, yflip=true, aspect_ratio=1, colorbar=false, axis=false, title="Confusion Matrix")

end


function printConfusionMatrix(outputs::AbstractArray{Bool,1}, targets::AbstractArray{Bool,1})
    """
    This function prints the confusion matrix and several metrics of a binary classifier given its boolean outputs and the target values.
    
    Parameters:
        - outputs: a 1D boolean array with the outputs of the classifier.
        - targets: a 1D boolean array with the target values.
    
    Returns:
        - Nothing
    """
    
    cm = confusionMatrix(outputs, targets)
    
    printMetrics(cm)

end

function printConfusionMatrix(outputs::AbstractArray{<:Real,1}, targets::AbstractArray{Bool,1}; threshold::Real = 0.5)

    """
    This function prints the confusion matrix and several metrics of a binary classifier given its real-valued outputs and the target values.
    
    Parameters:
        - outputs: a 1D real-valued array with the outputs of the classifier.
        - targets: a 1D boolean array with the target values.
        - threshold: a real number between 0 and 1 that defines the threshold for binary classification.
    
    Returns:
        - Nothing
    """
    
    cm = confusionMatrix(outputs, targets, threshold=threshold)
    
    printMetrics(cm)

end

""" 2.MULTI-CLASS CLASSIFIER EVALUATION """

function oneVSall(inputs::AbstractArray{<:Real,2}, targets::AbstractArray{Bool,2}; apply_softmax::Bool=false)
    numInstances, numClasses = size(targets)
    """
    This function simulates a one-vs-all multi-class classifier by training a binary classifier for each class.
    
    Parameters:
        - inputs: a matrix with the input patterns.
        - targets: a boolean matrix with the target values.
        - apply_softmax: a boolean that indicates whether to apply the softmax function to the outputs.
    
    Returns:
        - A boolean matrix with the outputs of the classifier.
        - A real-valued matrix with the outputs of the classifier before applying the softmax function.
    """
    
    outputs = Array{Float32,2}(undef, numInstances, numClasses)

    # Simulate binary classifier output for each class
    for numClass in 1:numClasses
        model = fit(inputs, targets[:,[numClass]])
        outputs[:,numClass] .= model(inputs)
    end

    # Optionally apply softmax to outputs
    if apply_softmax
        outputs = softmax(outputs')' 
    end    

    # Convert the output to a boolean matrix, ensuring only one 'true' per row
    vmax = maximum(outputs, dims=2)
    outputs_bool = (outputs .== vmax)
    
    # Resolve ties by keeping only the first occurrence of the maximum in each row
    for i in 1:numInstances
        max_indices = findall(outputs_bool[i, :])
        if length(max_indices) > 1
            # Keep only the first occurrence of the maximum value
            outputs_bool[i, :] .= false
            outputs_bool[i, max_indices[1]] = true
        end
    end

    return outputs_bool, outputs

end

function confusionMatrix(outputs::AbstractArray{Bool,2}, targets::AbstractArray{Bool,2}; weighted::Bool=true)
    """
    This function calculates the confusion matrix and several metrics of a multi-class classifier given its boolean outputs and the target values.
    
    Parameters:
        - outputs: a boolean matrix with the outputs of the classifier.
        - targets: a boolean matrix with the target values.
        - weighted: a boolean that indicates whether to calculate the metrics weighted by the number of instances of each class.
    
    Returns:
        - A dictionary with the following metrics:
            - accuracy: a real number between 0 and 1 with the accuracy of the classifier.
            - error_rate: a real number between 0 and 1 with the error rate of the classifier.
            - recall: a real number between 0 and 1 with the recall of the classifier.
            - precision: a real number between 0 and 1 with the precision of the classifier.
            - specifity: a real number between 0 and 1 with the specifity of the classifier.
            - negative_predictive_value: a real number between 0 and 1 with the negative predictive value of the classifier.
            - f1_score: a real number between 0 and 1 with the F-score of the classifier.
            - confusion_matrix: a matrix with the confusion matrix of the classifier.
        - A vector with a dictionary for the metrics of each class.
    """

    numClasses = size(outputs, 2)
    if numClasses != size(targets, 2) || numClasses == 2
        error("Invalid number of columns. Outputs and targets must have more than 2 classes and the same number of columns.")
    end

    if numClasses == 1
        return confusionMatrix(outputs[:, 1], targets[:, 1]), nothing
    end

    # Create a vector of any type to store the results of each class
    classes_results = Vector{Any}(undef, numClasses)

    recall = zeros(Float64, numClasses)
    specificity = zeros(Float64, numClasses)
    precision = zeros(Float64, numClasses)
    negative_predictive_value = zeros(Float64, numClasses)
    f1_score = zeros(Float64, numClasses)
    accuracy = zeros(Float64, numClasses)
    valid_classes = 0

    for class in 1:numClasses
        if any(targets[:, class])
            classes_results[class] = confusionMatrix(outputs[:, class], targets[:, class])
            recall[class] = classes_results[class][:recall]
            specificity[class] = classes_results[class][:specificity]
            precision[class] = classes_results[class][:precision]
            negative_predictive_value[class] = classes_results[class][:negative_predictive_value]
            f1_score[class] = classes_results[class][:f1_score]
            accuracy[class] = classes_results[class][:accuracy]
            valid_classes += 1
        end
    end

    conf_matrix = zeros(Int, numClasses, numClasses)
    for i in 1:numClasses
        for j in 1:numClasses
            conf_matrix[i, j] = sum(outputs[:, i] .& targets[:, j])
        end
    end

    if weighted
        class_weights = vec(sum(targets, dims=1) ./ sum(targets))
        agg_recall = sum(recall .* class_weights)
        agg_specificity = sum(specificity .* class_weights)
        agg_precision = sum(precision .* class_weights)
        agg_negative_predictive_value = sum(negative_predictive_value .* class_weights)
        agg_f1_score = sum(f1_score .* class_weights)
        agg_accuracy = sum(accuracy .* class_weights)
    else
        agg_recall = sum(recall) / valid_classes
        agg_specificity = sum(specificity) / valid_classes
        agg_precision = sum(precision) / valid_classes
        agg_negative_predictive_value = sum(negative_predictive_value) / valid_classes
        agg_f1_score = sum(f1_score) / valid_classes
        agg_accuracy = sum(accuracy) / valid_classes
    end
 
    error_rate = 1 - agg_accuracy

    return Dict(
        :accuracy => agg_accuracy,
        :error_rate => error_rate,
        :recall => agg_recall,
        :specificity => agg_specificity,
        :precision => agg_precision,
        :negative_predictive_value => agg_negative_predictive_value,
        :f1_score => agg_f1_score,
        :confusion_matrix => conf_matrix
    ), classes_results

end


function confusionMatrix(outputs::AbstractArray{<:Real,2}, targets::AbstractArray{Bool,2}; weighted::Bool=true)
    """
    This function calculates the confusion matrix and several metrics of a multi-class classifier given its real-valued outputs and the target values.
    
    Parameters:
        - outputs: a real-valued matrix with the outputs of the classifier.
        - targets: a boolean matrix with the target values.
        - weighted: a boolean that indicates whether to calculate the metrics weighted by the number of instances of each class.
    
    Returns:
        - A dictionary with the following metrics:
            - accuracy: a real number between 0 and 1 with the accuracy of the classifier.
            - error_rate: a real number between 0 and 1 with the error rate of the classifier.
            - recall: a real number between 0 and 1 with the recall of the classifier.
            - precision: a real number between 0 and 1 with the precision of the classifier.
            - specifity: a real number between 0 and 1 with the specifity of the classifier.
            - negative_predictive_value: a real number between 0 and 1 with the negative predictive value of the classifier.
            - f1_score: a real number between 0 and 1 with the F-score of the classifier.
            - confusion_matrix: a matrix with the confusion matrix of the classifier.
    """
    
    # Convert real-valued outputs to boolean using classifyOutputs
    bool_outputs = classifyOutputs(outputs)
    
    # Call the previously defined confusionMatrix for boolean outputs and targets
    return confusionMatrix(bool_outputs, targets; weighted=weighted)

end


function confusionMatrix(outputs::AbstractArray{<:Any,1}, targets::AbstractArray{<:Any,1}; weighted::Bool=true, target_labels::Vector{<:Any} = ["Dropout", "Graduate", "Enrolled"])
    """
    This function calculates the confusion matrix and several metrics of a multi-class classifier given its outputs and the target values without using oneHotEncoding.
    
    Parameters:
        - outputs: a vector with the outputs of the classifier.
        - targets: a vector with the target values.
        - weighted: a boolean that indicates whether to calculate the metrics weighted by the number of instances of each class.
    
    Returns:
        - A dictionary with the following metrics:
            - accuracy: a real number between 0 and 1 with the accuracy of the classifier.
            - error_rate: a real number between 0 and 1 with the error rate of the classifier.
            - recall: a real number between 0 and 1 with the recall of the classifier.
            - precision: a real number between 0 and 1 with the precision of the classifier.
            - specifity: a real number between 0 and 1 with the specifity of the classifier.
            - negative_predictive_value: a real number between 0 and 1 with the negative predictive value of the classifier.
            - f1_score: a real number between 0 and 1 with the F-score of the classifier.
            - confusion_matrix: a matrix with the confusion matrix of the classifier.
    """
    
    # Defensive line to ensure all output classes are in the target classes
    @assert (all([in(output, unique(targets)) for output in outputs])) "All output classes must be included in the target classes"
    
    # Check if label_targets is null
    if target_labels isa Nothing
        target_labels = vcat(unique(targets), unique(outputs))
    end
    
    
    # Encode both outputs and targets using oneHotEncoding
    bool_outputs = oneHotEncoding(outputs, target_labels)
    bool_targets = oneHotEncoding(targets, target_labels)
    
    # Call the previously defined confusionMatrix function for boolean matrices
    return confusionMatrix(bool_outputs, bool_targets; weighted=weighted)

end
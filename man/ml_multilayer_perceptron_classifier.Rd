% Generated by roxygen2: do not edit by hand
% Please edit documentation in
%   R/ml_classification_multilayer_perceptron_classifier.R
\name{ml_multilayer_perceptron_classifier}
\alias{ml_multilayer_perceptron_classifier}
\alias{ml_multilayer_perceptron}
\title{Spark ML -- Multilayer Perceptron}
\usage{
ml_multilayer_perceptron_classifier(
  x,
  formula = NULL,
  layers = NULL,
  max_iter = 100,
  step_size = 0.03,
  tol = 1e-06,
  block_size = 128,
  solver = "l-bfgs",
  seed = NULL,
  initial_weights = NULL,
  thresholds = NULL,
  features_col = "features",
  label_col = "label",
  prediction_col = "prediction",
  probability_col = "probability",
  raw_prediction_col = "rawPrediction",
  uid = random_string("multilayer_perceptron_classifier_"),
  ...
)

ml_multilayer_perceptron(
  x,
  formula = NULL,
  layers,
  max_iter = 100,
  step_size = 0.03,
  tol = 1e-06,
  block_size = 128,
  solver = "l-bfgs",
  seed = NULL,
  initial_weights = NULL,
  features_col = "features",
  label_col = "label",
  thresholds = NULL,
  prediction_col = "prediction",
  probability_col = "probability",
  raw_prediction_col = "rawPrediction",
  uid = random_string("multilayer_perceptron_classifier_"),
  response = NULL,
  features = NULL,
  ...
)
}
\arguments{
\item{x}{A \code{spark_connection}, \code{ml_pipeline}, or a \code{tbl_spark}.}

\item{formula}{Used when \code{x} is a \code{tbl_spark}. R formula as a character string or a formula. This is used to transform the input dataframe before fitting, see \link{ft_r_formula} for details.}

\item{layers}{A numeric vector describing the layers -- each element in the vector gives the size of a layer. For example, \code{c(4, 5, 2)} would imply three layers, with an input (feature) layer of size 4, an intermediate layer of size 5, and an output (class) layer of size 2.}

\item{max_iter}{The maximum number of iterations to use.}

\item{step_size}{Step size to be used for each iteration of optimization (> 0).}

\item{tol}{Param for the convergence tolerance for iterative algorithms.}

\item{block_size}{Block size for stacking input data in matrices to speed up the computation. Data is stacked within partitions. If block size is more than remaining data in a partition then it is adjusted to the size of this data. Recommended size is between 10 and 1000. Default: 128}

\item{solver}{The solver algorithm for optimization. Supported options: "gd" (minibatch gradient descent) or "l-bfgs". Default: "l-bfgs"}

\item{seed}{A random seed. Set this value if you need your results to be
reproducible across repeated calls.}

\item{initial_weights}{The initial weights of the model.}

\item{thresholds}{Thresholds in multi-class classification to adjust the probability of predicting each class. Array must have length equal to the number of classes, with values > 0 excepting that at most one value may be 0. The class with largest value \code{p/t} is predicted, where \code{p} is the original probability of that class and \code{t} is the class's threshold.}

\item{features_col}{Features column name, as a length-one character vector. The column should be single vector column of numeric values. Usually this column is output by \code{\link{ft_r_formula}}.}

\item{label_col}{Label column name. The column should be a numeric column. Usually this column is output by \code{\link{ft_r_formula}}.}

\item{prediction_col}{Prediction column name.}

\item{probability_col}{Column name for predicted class conditional probabilities.}

\item{raw_prediction_col}{Raw prediction (a.k.a. confidence) column name.}

\item{uid}{A character string used to uniquely identify the ML estimator.}

\item{...}{Optional arguments; see Details.}

\item{response}{(Deprecated) The name of the response column (as a length-one character vector.)}

\item{features}{(Deprecated) The name of features (terms) to use for the model fit.}
}
\value{
The object returned depends on the class of \code{x}.

\itemize{
  \item \code{spark_connection}: When \code{x} is a \code{spark_connection}, the function returns an instance of a \code{ml_estimator} object. The object contains a pointer to
  a Spark \code{Predictor} object and can be used to compose
  \code{Pipeline} objects.

  \item \code{ml_pipeline}: When \code{x} is a \code{ml_pipeline}, the function returns a \code{ml_pipeline} with
  the predictor appended to the pipeline.

  \item \code{tbl_spark}: When \code{x} is a \code{tbl_spark}, a predictor is constructed then
  immediately fit with the input \code{tbl_spark}, returning a prediction model.

  \item \code{tbl_spark}, with \code{formula}: specified When \code{formula}
    is specified, the input \code{tbl_spark} is first transformed using a
    \code{RFormula} transformer before being fit by
    the predictor. The object returned in this case is a \code{ml_model} which is a
    wrapper of a \code{ml_pipeline_model}.
}
}
\description{
Classification model based on the Multilayer Perceptron. Each layer has sigmoid activation function, output layer has softmax.
}
\details{
When \code{x} is a \code{tbl_spark} and \code{formula} (alternatively, \code{response} and \code{features}) is specified, the function returns a \code{ml_model} object wrapping a \code{ml_pipeline_model} which contains data pre-processing transformers, the ML predictor, and, for classification models, a post-processing transformer that converts predictions into class labels. For classification, an optional argument \code{predicted_label_col} (defaults to \code{"predicted_label"}) can be used to specify the name of the predicted label column. In addition to the fitted \code{ml_pipeline_model}, \code{ml_model} objects also contain a \code{ml_pipeline} object where the ML predictor stage is an estimator ready to be fit against data. This is utilized by \code{\link{ml_save}} with \code{type = "pipeline"} to faciliate model refresh workflows.

\code{ml_multilayer_perceptron()} is an alias for \code{ml_multilayer_perceptron_classifier()} for backwards compatibility.
}
\examples{
\dontrun{
sc <- spark_connect(master = "local")

iris_tbl <- sdf_copy_to(sc, iris, name = "iris_tbl", overwrite = TRUE)
partitions <- iris_tbl \%>\%
  sdf_random_split(training = 0.7, test = 0.3, seed = 1111)

iris_training <- partitions$training
iris_test <- partitions$test

mlp_model <- iris_training \%>\%
  ml_multilayer_perceptron_classifier(Species ~ ., layers = c(4, 3, 3))

pred <- ml_predict(mlp_model, iris_test)

ml_multiclass_classification_evaluator(pred)
}

}
\seealso{
See \url{https://spark.apache.org/docs/latest/ml-classification-regression.html} for
  more information on the set of supervised learning algorithms.

Other ml algorithms: 
\code{\link{ml_aft_survival_regression}()},
\code{\link{ml_decision_tree_classifier}()},
\code{\link{ml_gbt_classifier}()},
\code{\link{ml_generalized_linear_regression}()},
\code{\link{ml_isotonic_regression}()},
\code{\link{ml_linear_regression}()},
\code{\link{ml_linear_svc}()},
\code{\link{ml_logistic_regression}()},
\code{\link{ml_naive_bayes}()},
\code{\link{ml_one_vs_rest}()},
\code{\link{ml_random_forest_classifier}()}
}
\concept{ml algorithms}

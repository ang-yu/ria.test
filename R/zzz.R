# The default learner backends are called indirectly by mlr3superlearner.
#' @importFrom earth earth
#' @importFrom lightgbm lgb.train
#' @importFrom nnet nnet
NULL

.onLoad <- function(...) {
	S7::methods_register()
}

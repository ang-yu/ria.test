make_dataset <- function(data, x, device, weights = NULL) {
	n <- nrow(data$data)
	if (is.null(weights)) weights <- 1
	checkmate::assert_numeric(weights, any.missing = FALSE, finite = TRUE)
	if (!length(weights) %in% c(1L, n)) {
		stop("weights must have length 1 or match the number of training observations.")
	}
	if (length(weights) == 1L) weights <- rep(weights, n)

	self <- NULL
	dataset <- torch::dataset(
		name = "tmp_ria_test_dataset",
		initialize = function(data, x, device, weights) {
			for (df in names(data)) {
				if (ncol(data[[df]]) > 0) {
					df_x <- data[[df]][, x, drop = FALSE]
					self[[df]] <- one_hot_encode(df_x) |>
						as_torch(device = device)
				}
			}
			self$weights <- as_torch(weights, device = device)
		},
		.getitem = function(i) {
			fields <- grep("data", names(self), value = TRUE)
			batch <- setNames(lapply(fields, function(x) self[[x]][i, ]), fields)
			batch$weights <- self$weights[i, ]
			batch
		},
		.length = function() {
			self$data$size()[1]
		}
	)
	dataset(data, x, device, weights)
}

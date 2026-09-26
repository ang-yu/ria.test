test_that("Riesz training preserves the identity-shift optimum in every batch", {
	skip_if_not(torch::torch_is_installed())

	# With an identity shift and one observation per support point, the
	# empirical Riesz representer is exactly the previous-stage weight.
	weights <- c(1, 3, 2, 4, 9)
	data <- as.data.frame(diag(length(weights)))
	train <- list(data = data, data_shift = data)

	for (batch_size in c(1L, 2L, length(weights))) {
		gradients <- list()
		architecture <- torch::nn_module(
			initialize = function(input_size) {
				self$values <- torch::nn_parameter(torch::torch_tensor(
					matrix(weights, ncol = 1), dtype = torch::torch_float()
				))
				self$values$register_hook(function(gradient) {
					# Capture the loss gradient before Adam applies weight decay.
					gradients[[length(gradients) + 1L]] <<- as.numeric(gradient)
					gradient
				})
			},
			forward = function(x) x$matmul(self$values)
		)

		nn_sequential_riesz_representer(
			train = train,
			vars = names(data),
			architecture = architecture,
			.f = function(model, batch) model(batch$data_shift),
			weights = weights,
			batch_size = batch_size,
			learning_rate = 0,
			epochs = 1L,
			device = "cpu"
		)

		expect_length(gradients, ceiling(length(weights) / batch_size))
		for (gradient in gradients) {
			expect_equal(gradient, rep(0, length(weights)), tolerance = 1e-6)
		}
	}
})

test_that("Riesz training satisfies the finite-support shifted normal equations", {
	skip_if_not(torch::torch_is_installed())

	# Under a uniform empirical distribution and a permutation shift, the
	# exact representer at each point is the weight of its preimage.
	weights <- c(1, 3, 2, 4, 9)
	shift <- c(3L, 5L, 1L, 2L, 4L)
	representer <- weights[order(shift)]
	data <- as.data.frame(diag(length(weights)))
	train <- list(data = data, data_shift = data[shift, , drop = FALSE])
	gradients <- list()
	architecture <- torch::nn_module(
		initialize = function(input_size) {
			self$values <- torch::nn_parameter(torch::torch_tensor(
				matrix(representer, ncol = 1), dtype = torch::torch_float()
			))
			self$values$register_hook(function(gradient) {
				gradients[[length(gradients) + 1L]] <<- as.numeric(gradient)
				gradient
			})
		},
		forward = function(x) x$matmul(self$values)
	)

	nn_sequential_riesz_representer(
		train = train,
		vars = names(data),
		architecture = architecture,
		.f = function(model, batch) model(batch$data_shift),
		weights = weights,
		batch_size = length(weights),
		learning_rate = 0,
		epochs = 1L,
		device = "cpu"
	)

	expect_length(gradients, 1L)
	expect_equal(gradients[[1]], rep(0, length(weights)), tolerance = 1e-6)
})

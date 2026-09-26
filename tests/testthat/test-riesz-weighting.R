test_that("Riesz loss pairs each prediction with its own weight", {
	skip_if_not(torch::torch_is_installed(), "Torch runtime is not installed")

	observed <- torch::torch_tensor(
		matrix(c(2, 4), ncol = 1), requires_grad = TRUE
	)
	shifted <- torch::torch_tensor(
		matrix(c(2, 4), ncol = 1), requires_grad = TRUE
	)
	weights <- torch::torch_tensor(c(1, 3))

	loss <- ria.test:::riesz_loss(observed, shifted, weights)

	# Broadcasting these column predictions across all weights gives -2 instead.
	expect_equal(as.numeric(loss), -4)
	loss$backward()
	expect_equal(as.numeric(observed$grad), c(2, 4))
	expect_equal(as.numeric(shifted$grad), c(-1, -3))
})

test_that("Riesz loss handles singleton batches and rejects unequal lengths", {
	skip_if_not(torch::torch_is_installed(), "Torch runtime is not installed")

	observed <- torch::torch_tensor(matrix(2, ncol = 1), requires_grad = TRUE)
	shifted <- torch::torch_tensor(4, requires_grad = TRUE)
	weights <- torch::torch_tensor(matrix(3, ncol = 1))
	loss <- ria.test:::riesz_loss(observed, shifted, weights)

	expect_equal(as.numeric(loss), -20)
	loss$backward()
	expect_equal(as.numeric(observed$grad), 4)
	expect_equal(as.numeric(shifted$grad), -6)

	pair <- torch::torch_tensor(c(1, 2))
	single <- torch::torch_tensor(1)
	expect_error(ria.test:::riesz_loss(pair, pair, single))
	expect_error(ria.test:::riesz_loss(pair, single, pair))
})

test_that("minibatches keep weights aligned with original and shifted rows", {
	skip_if_not(torch::torch_is_installed(), "Torch runtime is not installed")

	ids <- seq_len(7)
	weights <- c(2, -1, 7, 0.5, 4, 10, 3)
	data <- list(
		data = data.frame(id = ids, value = 10 * ids),
		data_0 = data.frame(id = ids, value = 10 * ids + 100),
		data_1 = data.frame(id = ids, value = 10 * ids + 200)
	)
	dataset <- ria.test:::make_dataset(
		data, c("id", "value"), device = "cpu", weights = weights
	)

	for (shuffle in c(FALSE, TRUE)) {
		batches <- torch::dataloader(dataset, batch_size = 3, shuffle = shuffle)
		seen <- numeric()
		batch_sizes <- integer()
		coro::loop(for (batch in batches) {
			batch_ids <- as.numeric(batch$data[, 1])
			seen <- c(seen, batch_ids)
			batch_sizes <- c(batch_sizes, length(batch_ids))
			expect_equal(as.numeric(batch$weights), weights[batch_ids])
			expect_equal(as.numeric(batch$data[, 2]), 10 * batch_ids)
			expect_equal(as.numeric(batch$data_0[, 1]), batch_ids)
			expect_equal(as.numeric(batch$data_0[, 2]), 10 * batch_ids + 100)
			expect_equal(as.numeric(batch$data_1[, 1]), batch_ids)
			expect_equal(as.numeric(batch$data_1[, 2]), 10 * batch_ids + 200)
			expect_true(torch::torch_is_floating_point(batch$weights))
			expect_identical(batch$weights$device$type, "cpu")
		})
		expect_equal(sort(seen), ids)
		expect_identical(batch_sizes, c(3L, 3L, 1L))
	}
})

test_that("Riesz datasets expand unit and scalar weights over observations", {
	skip_if_not(torch::torch_is_installed(), "Torch runtime is not installed")

	data <- list(data = data.frame(id = seq_len(4)))
	unit <- ria.test:::make_dataset(data, "id", device = "cpu")
	scalar <- ria.test:::make_dataset(data, "id", device = "cpu", weights = 2)

	expect_equal(as.numeric(unit$weights), rep(1, 4))
	expect_equal(as.numeric(scalar$weights), rep(2, 4))
	expect_true(torch::torch_is_floating_point(unit$weights))
	expect_true(torch::torch_is_floating_point(scalar$weights))
})

test_that("Riesz datasets reject invalid observation weights", {
	skip_if_not(torch::torch_is_installed(), "Torch runtime is not installed")

	data <- list(data = data.frame(id = seq_len(4)))
	for (weights in list(numeric(), c(1, 2), NA_real_, Inf, c(1, 2, NaN, 4))) {
		expect_error(
			ria.test:::make_dataset(data, "id", device = "cpu", weights = weights),
			"weights"
		)
	}
})

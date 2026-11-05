test_that("the package estimates only the quantities needed for the test", {
	params <- ria.test:::estimation_parameters

	expect_named(params, c("natural", "randomized"))
	expect_length(params$natural, 2L)
	expect_length(params$randomized, 3L)
	expect_false("estimand" %in% names(formals(ria.test)))
	expect_true(all(c("pre", "post") %in% names(formals(ria.test))))
	expect_identical(formals(ria.test)$pre, quote(expr = ))
	expect_identical(formals(ria.test)$post, quote(expr = ))
})

test_that("the test estimand set contains all Table 1 quantities", {
	natural_eif <- list("111" = 8, "000" = 1)
	ria_eif <- list("1111" = 9, "1100" = 5, "0000" = 3)
	estimates <- ria.test:::calculate_estimates(natural_eif, ria_eif)

	expect_named(estimates, c("TE", "TE^R", "TE - TE^R", "NIE^R", "NDE^R"))
	expect_equal(
		unlist(estimates),
		c("TE" = 7, "TE^R" = 6, "TE - TE^R" = 1, "NIE^R" = 4, "NDE^R" = 2)
	)
})

test_that("unit scores are centered before weighted cluster sums are formed", {
	data <- data.frame(d = 0, m = 0, y = 0, id = c(1, 2, 2, 2))
	vars <- ria.test_vars(D = "d", M = "m", Y = "y", L = NA_character_, id = "id")
	weights <- c(2, 1, 1, 4)
	identity_shift <- function(data, trt) data[[trt]]
	cd <- ria.test_data(data, vars, weights, identity_shift, identity_shift)

	base <- c(4, 0, 0, 0)
	scores <- cbind(base = base, shifted = base + 1)
	estimates <- calc_eifs(cd, list(scores), NULL,
		function(cd, theta, alpha, key) alpha[[1]][, key])

	# The weighted mean is 1. The two centered cluster totals are 6 and -6
	# on the original weight scale, with total weight 8.
	expect_equal(estimates$base@x, 1)
	expect_equal(estimates$base@std_error, 1.5)
	contrast <- estimates$shifted - estimates$base
	expect_equal(contrast@x, 1)
	expect_equal(contrast@std_error, 0)
})

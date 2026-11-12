test_that("default learners produce weighted predictions for both outcome types", {
	learners <- eval(formals(ria.test)$learners)
	expect_identical(learners, c("lightgbm", "mean", "earth", "nnet"))
	if (!"mlr3extralearners" %in% .packages()) {
		attachNamespace("mlr3extralearners")
		on.exit(detach("package:mlr3extralearners"), add = TRUE)
	}
	set.seed(42)
	data <- data.frame(x = rnorm(240), z = rnorm(240))
	binary_y <- rbinom(nrow(data), 1, plogis(0.6 * data$x))
	newdata <- list(data = data[1:10, ])

	for (type in c("continuous", "binomial")) {
		data$y <- if (type == "continuous") data$x + rnorm(nrow(data)) else binary_y
		utils::capture.output(
			fit <- fit_theta_regression(data, "y", learners, type, 3L, newdata)
		)
		expect_false(fit$discrete)
		expect_length(fit$learners, 4L)
		expect_true(all(is.finite(fit$weights) & fit$weights >= 0))
		expect_equal(sum(fit$weights), 1)

		predictions <- vapply(fit$learners, function(model) {
			pred <- model$predict_newdata(newdata$data)
			if (type == "continuous") pred$response else pred$prob[, "1"]
		}, numeric(nrow(newdata$data)))
		ids <- vapply(fit$learners, function(model) model$id, character(1))
		expect_equal(fit$preds$data, as.vector(predictions %*% fit$weights[ids]))
	}
})

test_that("constant continuous outcomes retain the Super Learner prediction interface", {
	data <- data.frame(x = seq_len(12), y = 0)
	newdata <- list(data = data[1:3, ], shifted = data[4:8, ])

	for (constant in c(-2.5, 0, 1)) {
		data$y <- constant
		fit <- fit_theta_regression(
			data, "y", c("glm", "ranger"), "continuous", 2L, newdata
		)

		expect_s3_class(fit, "mlr3superlearner")
		expect_equal(fit$weights, c(regr.featureless = 1))
		expect_named(fit$preds, names(newdata))
		for (name in names(newdata)) {
			expect_equal(fit$preds[[name]], rep(constant, nrow(newdata[[name]])), tolerance = 0)
			expect_equal(predict(fit, newdata[[name]]), fit$preds[[name]], tolerance = 0)
		}
	}
})

test_that("constant outcomes propagate through natural and randomized regressions", {
	data <- data.frame(
		D = rep(0:1, 6), C = seq_len(12), L = sin(seq_len(12)),
		M = cos(seq_len(12)), Y = 2.5
	)
	train <- list(
		data = data,
		data_0 = transform(data, D = 0),
		data_1 = transform(data, D = 1),
		data_0lp = transform(data, D = 0, L = rev(L)),
		data_1lp = transform(data, D = 1, L = rev(L))
	)
	valid <- lapply(train, function(data) data[1:3, ])
	vars <- ria.test_vars(D = "D", C = "C", L = "L", M = "M", Y = "Y")
	fit <- theta(train, valid, vars, estimation_parameters,
		c("mean", "glm", "ranger"), ria.test.control(mlr3superlearner_folds = 2L))

	expect_named(fit, c("n", "r"))
	expect_length(fit$n, 2L)
	expect_length(fit$r, 3L)
	for (effects in fit) {
		for (effect in effects) {
			for (name in names(effect)) {
				if (grepl("_weights$", name)) {
					expect_equal(effect[[name]], c(regr.featureless = 1))
				} else {
					expect_equal(effect[[name]], rep(2.5, 3), tolerance = 0)
				}
			}
		}
	}
})

test_that("nonconstant outcomes use the requested learner", {
	data <- data.frame(x = seq_len(12), y = seq_len(12)^2)
	fit <- fit_theta_regression(data, "y", "glm", "continuous", 2L, list(data = data))
	expect_equal(fit$weights, c(regr.lm = 1))
	expect_gt(diff(range(predict(fit, data))), 0)
})

test_that("learner weights align across constant and nonconstant folds", {
	weights <- list(fit2_weights = list("111" = list(
		c(regr.lm = 1, regr.ranger = 0),
		c(regr.featureless = 1),
		c(regr.ranger = 0.6, regr.lm = 0.4)
	)))
	expect_equal(simplify_weights(weights), list(fit2_weights = list("111" = data.frame(
		regr.lm = c(1, 0, 0.4),
		regr.ranger = c(0, 0, 0.6),
		regr.featureless = c(0, 1, 0)
	))))
})

test_that("other outcomes and fitting errors are not hidden by the constant fallback", {
	learners <- c("glm", "ranger")
	local_mocked_bindings(
		mlr3superlearner = function(..., library) {
			expect_identical(library, learners)
			stop("original fitting error")
		},
		.package = "mlr3superlearner"
	)

	# No tolerance or removal of missing/nonfinite values is used to detect constants.
	for (y in list(numeric(), c(2, 3), c(1, 1 + .Machine$double.eps),
			c(2, NA_real_), rep(NA_real_, 2), rep(NaN, 2), rep(Inf, 2), rep(-Inf, 2))) {
		expect_error(
			fit_theta_regression(data.frame(x = seq_along(y), y = y), "y", learners,
				"continuous", 2L, NULL),
			"original fitting error", fixed = TRUE
		)
	}
	expect_error(
		fit_theta_regression(data.frame(x = 1:2, y = 1), "y", learners,
			"binomial", 2L, NULL),
		"original fitting error", fixed = TRUE
	)
})

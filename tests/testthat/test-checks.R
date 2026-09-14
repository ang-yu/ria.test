test_that("detects missing variables", {
	foo <- data.frame(d = 1, w = 1, m = 1, l = NA, y = 1)
	expect_error(
		ria.test(foo, "d", "y", "m", "l", "w"),
		"Assertion on 'data' failed: Missing data found in treatment/covariate/mediator/observed nodes."
	)
})

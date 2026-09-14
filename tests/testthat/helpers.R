gendata <- function(n = 1e3) {
	w <- rbinom(n, 1, 0.25)
	d <- rbinom(n, 1, 0.5)
	l <- rbinom(n, 1, plogis(0.25*w + 0.75*d))
	m <- rbinom(n, 1, plogis(0.125*w + 0.5*d - 0.25*l))
	y <- rbinom(n, 1, plogis(-1 + 0.25*w + 0.75*d + 0.25*l + 0.25*m))
	data.frame(
		w = w,
		d = d,
		l = l,
		m = m,
		y = y
	)
}

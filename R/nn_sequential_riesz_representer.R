#' @importFrom checkmate `%??%`
nn_sequential_riesz_representer <- function(train,
																						vars,
																						architecture,
																						.f,
																						weights = NULL,
																						batch_size,
																						learning_rate,
																						epochs,
																						device) {
	dataset <- make_dataset(train, vars, device = device, weights = weights)
	train_dl <- torch::dataloader(dataset, batch_size = batch_size)
	model <- architecture(ncol(dataset$data))
	model$to(device = device)

	optimizer <- torch::optim_adam(
		params = c(model$parameters),
		lr = learning_rate,
		weight_decay = 0.01
	)

	scheduler <- torch::lr_one_cycle(
		optimizer,
		max_lr = learning_rate,
		total_steps = epochs
	)

	p <- progressr::progressor(steps = epochs)

	for (epoch in 1:epochs) {
		coro::loop(for (b in train_dl) {
			loss <- riesz_loss(model(b$data), .f(model, b), b$weights)

			optimizer$zero_grad()
			loss$backward()

			optimizer$step()
		})
		scheduler$step()
		p()
	}

	model$eval()
	model
}

riesz_loss <- function(predictions, shifted_predictions, weights) {
	# A column times a vector broadcasts across observations, so flatten all three.
	predictions <- predictions$reshape(c(-1))
	shifted_predictions <- shifted_predictions$reshape(c(-1))
	weights <- weights$reshape(c(-1))
	if (predictions$numel() != shifted_predictions$numel() ||
			predictions$numel() != weights$numel()) {
		stop("Riesz loss requires one prediction and one weight per observation.")
	}
	(predictions$pow(2) - 2 * weights * shifted_predictions)$mean(dtype = torch::torch_float())
}

#' Parametric survival regression
#'
#' @description
#' `survival_reg()` defines a parametric survival model. This function can fit
#' censored regression models.
#'
#' \Sexpr[stage=render,results=rd]{parsnip:::make_engine_list("survival_reg")}
#'
#' More information on how \pkg{parsnip} is used for modeling is at
#' \url{https://www.tidymodels.org/}.
#'
#' @inheritParams boost_tree
#' @param mode A single character string for the prediction outcome mode.
#'  The only possible value for this model is "censored regression".
#' @param dist A character string for the probability distribution of the
#'  outcome. The default is "weibull".
#'
#'
#' @template spec-details
#'
#' @template spec-survival
#'
#' @template spec-references
#'
#' @seealso \Sexpr[stage=render,results=rd]{parsnip:::make_seealso_list("survival_reg")}
#'
#' @examples
#' show_engines("survival_reg")
#'
#' survival_reg(mode = "censored regression", dist = "weibull")
#' @keywords internal
#' @export
survival_reg <- function(mode = "censored regression", engine = "survival", dist = NULL) {

  args <- list(
    dist = enquo(dist)
  )

  new_model_spec(
    "survival_reg",
    args = args,
    eng_args = NULL,
    mode = mode,
    method = NULL,
    engine = engine
  )
}

#' @export
print.survival_reg <- function(x, ...) {
  cat("Parametric Survival Regression Model Specification (", x$mode, ")\n\n", sep = "")
  model_printer(x, ...)

  if (!is.null(x$method$fit$args)) {
    cat("Model fit template:\n")
    print(show_call(x))
  }

  invisible(x)
}

# ------------------------------------------------------------------------------

#' @method update survival_reg
#' @rdname parsnip_update
#' @export
update.survival_reg <- function(object, parameters = NULL, dist = NULL, fresh = FALSE, ...) {

  eng_args <- update_engine_parameters(object$eng_args, ...)

  if (!is.null(parameters)) {
    parameters <- check_final_param(parameters)
  }

  args <- list(
    dist = enquo(dist)
  )

  args <- update_main_parameters(args, parameters)

  if (fresh) {
    object$args <- args
    object$eng_args <- eng_args
  } else {
    null_args <- map_lgl(args, null_value)
    if (any(null_args))
      args <- args[!null_args]
    if (length(args) > 0)
      object$args[names(args)] <- args
    if (length(eng_args) > 0)
      object$eng_args[names(eng_args)] <- eng_args
  }

  new_model_spec(
    "survival_reg",
    args = object$args,
    eng_args = object$eng_args,
    mode = object$mode,
    method = NULL,
    engine = object$engine
  )
}


#' @export
translate.survival_reg <- function(x, engine = x$engine, ...) {
  if (is.null(engine)) {
    message("Used `engine = 'survival'` for translation.")
    engine <- "survival"
  }
  x <- translate.default(x, engine, ...)
  x
}


check_args.survival_reg <- function(object) {

  if (object$engine == "flexsurv") {

    args <- lapply(object$args, rlang::eval_tidy)

    # `dist` has no default in the function
    if (all(names(args) != "dist") || is.null(args$dist))
      object$args$dist <- "weibull"
  }

  invisible(object)
}

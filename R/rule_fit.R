#' RuleFit models
#'
#' @description
#' `rule_fit()` defines a model that derives simple feature rules from a tree
#' ensemble and uses them as features in a regularized model. This function can
#' fit classification and regression models.
#'
#' \Sexpr[stage=render,results=rd]{parsnip:::make_engine_list("rule_fit")}
#'
#' More information on how \pkg{parsnip} is used for modeling is at
#' \url{https://www.tidymodels.org/}.
#'
#' @inheritParams boost_tree
#' @param penalty L1 regularization parameter.
#' @details
#' The RuleFit model creates a regression model of rules in two stages. The
#'  first stage uses a tree-based model that is used to generate a set of rules
#'  that can be filtered, modified, and simplified. These rules are then added
#'  as predictors to a regularized generalized linear model that can also
#'  conduct feature selection during model training.
#'
#' @references Friedman, J. H., and Popescu, B. E. (2008). "Predictive learning
#' via rule ensembles." _The Annals of Applied Statistics_, 2(3), 916-954.
#'
#' @template spec-details
#'
#' @template spec-references
#'
#' @seealso [xrf::xrf.formula()], \Sexpr[stage=render,results=rd]{parsnip:::make_seealso_list("rule_fit")}
#'
#' @examples
#' show_engines("rule_fit")
#'
#' rule_fit()
#'
#' @export
rule_fit <-
  function(mode = "unknown",
           mtry = NULL, trees = NULL, min_n = NULL,
           tree_depth = NULL, learn_rate = NULL,
           loss_reduction = NULL,
           sample_size = NULL,
           penalty = NULL,
           engine = "xrf") {

    args <- list(
      mtry = enquo(mtry),
      trees = enquo(trees),
      min_n = enquo(min_n),
      tree_depth = enquo(tree_depth),
      learn_rate = enquo(learn_rate),
      loss_reduction = enquo(loss_reduction),
      sample_size = enquo(sample_size),
      penalty = enquo(penalty)
    )


    new_model_spec(
      "rule_fit",
      args = args,
      eng_args = NULL,
      mode = mode,
      method = NULL,
      engine = engine
    )
  }

#' @export
print.rule_fit <- function(x, ...) {
  cat("RuleFit Model Specification (", x$mode, ")\n\n", sep = "")
  model_printer(x, ...)

  if (!is.null(x$method$fit$args)) {
    cat("Model fit template:\n")
    print(show_call(x))
  }

  invisible(x)
}


# ------------------------------------------------------------------------------

#' @param object A `rule_fit` model specification.
#' @examples
#' # ------------------------------------------------------------------------------
#'
#' model <- rule_fit(trees = 10, min_n = 2)
#' model
#' update(model, trees = 1)
#' update(model, trees = 1, fresh = TRUE)
#' @method update rule_fit
#' @rdname parsnip_update
#' @inheritParams parsnip_update
#' @inheritParams rule_fit
#' @export
update.rule_fit <-
  function(object,
           parameters = NULL,
           mtry = NULL, trees = NULL, min_n = NULL,
           tree_depth = NULL, learn_rate = NULL,
           loss_reduction = NULL, sample_size = NULL,
           penalty = NULL,
           fresh = FALSE, ...) {
    update_dot_check(...)

    if (!is.null(parameters)) {
      parameters <- check_final_param(parameters)
    }

    args <- list(
      mtry = enquo(mtry),
      trees = enquo(trees),
      min_n = enquo(min_n),
      tree_depth = enquo(tree_depth),
      learn_rate = enquo(learn_rate),
      loss_reduction = enquo(loss_reduction),
      sample_size = enquo(sample_size),
      penalty = enquo(penalty)
    )

    args <- update_main_parameters(args, parameters)

    if (fresh) {
      object$args <- args
    } else {
      null_args <- map_lgl(args, null_value)
      if (any(null_args))
        args <- args[!null_args]
      if (length(args) > 0)
        object$args[names(args)] <- args
    }

    new_model_spec(
      "rule_fit",
      args = object$args,
      eng_args = object$eng_args,
      mode = object$mode,
      method = NULL,
      engine = object$engine
    )
  }

# ------------------------------------------------------------------------------

set_new_model("rule_fit")
set_model_mode("rule_fit", "classification")
set_model_mode("rule_fit", "regression")

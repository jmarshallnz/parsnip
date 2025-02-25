library(testthat)
library(parsnip)
library(rlang)

# ------------------------------------------------------------------------------

context("mars tests")
source(test_path("helpers.R"))
source(test_path("helper-objects.R"))
hpc <- hpc_data[1:150, c(2:5, 8)]

# ------------------------------------------------------------------------------

test_that('primary arguments', {
  basic <- mars(mode = "regression")
  basic_mars <- translate(basic %>% set_engine("earth"))
  expect_equal(basic_mars$method$fit$args,
               list(
                 formula = expr(missing_arg()),
                 data = expr(missing_arg()),
                 weights = expr(missing_arg()),
                 keepxy = TRUE
               )
  )

  num_terms <- mars(num_terms = 4, mode = "classification")
  num_terms_mars <- translate(num_terms %>% set_engine("earth"))
  expect_equal(num_terms_mars$method$fit$args,
               list(
                 formula = expr(missing_arg()),
                 data = expr(missing_arg()),
                 weights = expr(missing_arg()),
                 nprune = new_empty_quosure(4),
                 glm = rlang::quo(list(family = stats::binomial)),
                 keepxy = TRUE
               )
  )

  prod_degree <- mars(prod_degree = 1, mode = "regression")
  prod_degree_mars <- translate(prod_degree %>% set_engine("earth"))
  expect_equal(prod_degree_mars$method$fit$args,
               list(
                 formula = expr(missing_arg()),
                 data = expr(missing_arg()),
                 weights = expr(missing_arg()),
                 degree = new_empty_quosure(1),
                 keepxy = TRUE
               )
  )

  prune_method_v <- mars(prune_method = tune(), mode = "regression")
  prune_method_v_mars <- translate(prune_method_v %>% set_engine("earth"))
  expect_equal(prune_method_v_mars$method$fit$args,
               list(
                 formula = expr(missing_arg()),
                 data = expr(missing_arg()),
                 weights = expr(missing_arg()),
                 pmethod = new_empty_quosure(tune()),
                 keepxy = TRUE
               )
  )
})

test_that('engine arguments', {
  mars_keep <- mars(mode = "regression")
  expect_equal(translate(mars_keep %>% set_engine("earth", keepxy = FALSE))$method$fit$args,
               list(
                 formula = expr(missing_arg()),
                 data = expr(missing_arg()),
                 weights = expr(missing_arg()),
                 keepxy = new_empty_quosure(FALSE)
               )
  )
})


test_that('updating', {
  expr1     <- mars() %>% set_engine("earth", model = FALSE)
  expr1_exp <- mars(num_terms = 1) %>% set_engine("earth", model = FALSE)

  expr2     <- mars(num_terms = tune()) %>% set_engine("earth", nk = tune())
  expr2_exp <- mars(num_terms = tune()) %>% set_engine("earth", nk = 10)

  expr3     <- mars(num_terms = 1, prod_degree = tune()) %>% set_engine("earth", nk = tune())
  expr3_fre <- mars(num_terms = 1) %>% set_engine("earth", nk = tune())
  expr3_exp <- mars(num_terms = 1) %>% set_engine("earth", nk = 10)

  expr4     <- mars(num_terms = 0) %>% set_engine("earth", nk = 10)
  expr4_exp <- mars(num_terms = 0) %>% set_engine("earth", nk = 10, trace = 2)

  expr5     <- mars(num_terms = 1) %>% set_engine("earth", nk = 10)
  expr5_exp <- mars(num_terms = 1) %>% set_engine("earth", nk = 10, trace = 2)

  expect_equal(update(expr1, num_terms = 1), expr1_exp)
  expect_equal(update(expr2, nk = 10), expr2_exp)
  expect_equal(update(expr3, num_terms = 1, fresh = TRUE), expr3_fre)
  expect_equal(update(expr3, num_terms = 1, fresh = TRUE, nk = 10), expr3_exp)

  param_tibb <- tibble::tibble(num_terms = 3, prod_degree = 1)
  param_list <- as.list(param_tibb)

  expr4_updated <- update(expr4, param_tibb)
  expect_equal(expr4_updated$args$num_terms, 3)
  expect_equal(expr4_updated$args$prod_degree, 1)
  expect_equal(expr4_updated$eng_args$nk, rlang::quo(10))

  expr4_updated_lst <- update(expr4, param_list)
  expect_equal(expr4_updated_lst$args$num_terms, 3)
  expect_equal(expr4_updated_lst$args$prod_degree, 1)
  expect_equal(expr4_updated_lst$eng_args$nk, rlang::quo(10))
})

test_that('bad input', {
  expect_error(translate(mars(mode = "regression") %>% set_engine()))
  expect_error(translate(mars() %>% set_engine("wat?")))
  expect_error(translate(mars(formula = y ~ x)))
})

# ------------------------------------------------------------------------------

num_pred <- colnames(hpc)[1:3]
hpc_bad_form <- as.formula(class ~ term)
hpc_basic <- mars(mode = "regression") %>% set_engine("earth")

# ------------------------------------------------------------------------------

test_that('mars execution', {
  skip_if_not_installed("earth")

  expect_error(
    res <- fit(
      hpc_basic,
      compounds ~ log(input_fields) + class,
      data = hpc,
      control = ctrl
    ),
    regexp = NA
  )
  expect_output(print(res), "parsnip model object")

  expect_error(
    res <- fit_xy(
      hpc_basic,
      x = hpc[, num_pred],
      y = hpc$num_pending,
      control = ctrl
    ),
    regexp = NA
  )

  expect_true(has_multi_predict(res))
  expect_equal(multi_predict_args(res), "num_terms")

  expect_error(
    res <- fit(
      hpc_basic,
      hpc_bad_form,
      data = hpc,
      control = ctrl
    ),
    regexp = "For a regression model"
  )

  ## multivariate y

  expect_error(
    res <- fit(
      hpc_basic,
      cbind(compounds, input_fields) ~ .,
      data = hpc,
      control = ctrl
    ),
    regexp = NA
  )

  expect_error(
    res <- fit_xy(
      hpc_basic,
      x = hpc[, 1:2],
      y = hpc[3:4],
      control = ctrl
    ),
    regexp = NA
  )
  parsnip:::load_libs(res, attach = TRUE)

})

test_that('mars prediction', {
  skip_if_not_installed("earth")

  uni_pred <- c(30.1466666666667, 30.1466666666667, 30.1466666666667,
                30.1466666666667, 30.1466666666667)
  inl_pred <- c(538.268789262046, 141.024903718634, 141.024903718634,
                141.024903718634, 141.024903718634)
  mv_pred <-
    structure(
      list(compounds =
             c(371.334864384913, 129.475162245595, 256.094366313268,
               129.475162245595, 129.475162245595),
           input_fields =
             c(430.476046435458, 158.833790342308, 218.07635084308,
               158.833790342308, 158.833790342308)
      ),
      class = "data.frame", row.names = c(NA, -5L)
    )

  res_xy <- fit_xy(
    hpc_basic,
    x = hpc[, num_pred],
    y = hpc$num_pending,
    control = ctrl
  )

  expect_equal(uni_pred, predict(res_xy, hpc[1:5, num_pred])$.pred)

  res_form <- fit(
    hpc_basic,
    compounds ~ log(input_fields) + class,
    data = hpc,
    control = ctrl
  )
  expect_equal(inl_pred, predict(res_form, hpc[1:5, ])$.pred)

  res_mv <- fit(
    hpc_basic,
    cbind(compounds, input_fields) ~ .,
    data = hpc,
    control = ctrl
  )
  expect_equal(
    setNames(mv_pred, paste0(".pred_", names(mv_pred))) %>% as.data.frame(),
    predict(res_mv, hpc[1:5,]) %>% as.data.frame()
  )
})


test_that('submodel prediction', {
  skip_if_not_installed("earth")

  reg_fit <-
    mars(
      num_terms = 20,
      mode = "regression",
      prune_method = "none"
    ) %>%
    set_engine("earth", keepxy = TRUE) %>%
    fit(mpg ~ ., data = mtcars[-(1:4), ])

  parsnip:::load_libs(reg_fit$spec, quiet = TRUE, attach = TRUE)
  tmp_reg <- reg_fit$fit
  tmp_reg$call[["pmethod"]] <- eval_tidy(tmp_reg$call[["pmethod"]])
  tmp_reg$call[["keepxy"]]  <- eval_tidy(tmp_reg$call[["keepxy"]])
  tmp_reg$call[["nprune"]]  <- eval_tidy(tmp_reg$call[["nprune"]])


  pruned_reg <- update(tmp_reg, nprune = 5)
  pruned_reg_pred <- predict(pruned_reg, mtcars[1:4, -1])[,1]

  mp_res <- multi_predict(reg_fit, new_data = mtcars[1:4, -1], num_terms = 5)
  mp_res <- do.call("rbind", mp_res$.pred)
  expect_equal(mp_res[[".pred"]], pruned_reg_pred)

  full_churn <- wa_churn[complete.cases(wa_churn), ]
  vars <- c("female", "tenure", "total_charges", "phone_service", "monthly_charges")
  class_fit <-
    mars(mode = "classification", prune_method = "none")  %>%
    set_engine("earth", keepxy = TRUE) %>%
    fit(churn ~ .,
        data = full_churn[-(1:4), c("churn", vars)])

  cls_fit <- class_fit$fit
  cls_fit$call[["pmethod"]] <- eval_tidy(cls_fit$call[["pmethod"]])
  cls_fit$call[["keepxy"]]  <- eval_tidy(cls_fit$call[["keepxy"]])
  cls_fit$call[["glm"]]  <- eval_tidy(cls_fit$call[["glm"]])

  pruned_cls <- update(cls_fit, nprune = 5)
  pruned_cls_pred <- predict(pruned_cls, full_churn[1:4, vars], type = "response")[,1]

  mp_res <- multi_predict(class_fit, new_data = full_churn[1:4, vars], num_terms = 5, type = "prob")
  mp_res <- do.call("rbind", mp_res$.pred)
  expect_equal(mp_res[[".pred_No"]], pruned_cls_pred)

  expect_error(
    multi_predict(reg_fit, newdata = mtcars[1:4, -1], num_terms = 5),
    "Did you mean"
  )
})


# ------------------------------------------------------------------------------

test_that('classification', {
  skip_if_not_installed("earth")

  expect_error(
    glm_mars <-
      mars(mode = "classification")  %>%
      set_engine("earth") %>%
      fit(Class ~ ., data = lending_club[-(1:5),]),
    regexp = NA
  )
  expect_true(!is.null(glm_mars$fit$glm.list))
  parsnip_pred <- predict(glm_mars, new_data = lending_club[1:5, -ncol(lending_club)], type = "prob")

  earth_pred <-
    c(0.95631355972526, 0.971917781277731, 0.894245392500336, 0.962667553751077,
      0.985827594261896)

  expect_equal(parsnip_pred$.pred_good, earth_pred)
})

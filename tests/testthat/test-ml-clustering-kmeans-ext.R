skip_on_livy()
skip_on_arrow_devel()

skip_databricks_connect()
test_that("ml_kmeans() param setting", {
  test_requires_version("3.0.0")
  sc <- testthat_spark_connection()
  test_args <- list(
    k = 3,
    max_iter = 30,
    init_steps = 4,
    init_mode = "random",
    seed = 234,
    features_col = "wfaaefa",
    prediction_col = "awiefjaw"
  )
  test_param_setting(sc, ml_kmeans, test_args)
})

test_that("'ml_kmeans' and 'kmeans' produce similar fits", {
  sc <- testthat_spark_connection()
  test_requires_version("2.0.0", "ml_kmeans() requires Spark 2.0.0+")

  iris_tbl <- testthat_tbl("iris")

  set.seed(123)
  iris <- iris %>%
    rename(
      Sepal_Length = Sepal.Length,
      Petal_Length = Petal.Length
    )

  R <- iris %>%
    select(Sepal_Length, Petal_Length) %>%
    kmeans(centers = 3)

  S <- iris_tbl %>%
    select(Sepal_Length, Petal_Length) %>%
    ml_kmeans(~., k = 3L)

  lhs <- as.matrix(R$centers)
  rhs <- as.matrix(S$centers)

  # ensure lhs, rhs are in same order (since labels may
  # not match between the two fits)
  lhs <- lhs[order(lhs[, 1]), ]
  rhs <- rhs[order(rhs[, 1]), ]
  expect_equivalent(lhs, rhs)
})

test_that("'ml_kmeans' supports 'features' argument for backwards compat (#1150)", {
  sc <- testthat_spark_connection()
  iris_tbl <- testthat_tbl("iris")

  set.seed(123)
  iris <- iris %>%
    rename(
      Sepal_Length = Sepal.Length,
      Petal_Length = Petal.Length
    )

  R <- iris %>%
    select(Sepal_Length, Petal_Length) %>%
    kmeans(centers = 3)

  S <- iris_tbl %>%
    select(Sepal_Length, Petal_Length) %>%
    ml_kmeans(k = 3L, features = c("Sepal_Length", "Petal_Length"))

  lhs <- as.matrix(R$centers)
  rhs <- as.matrix(S$centers)

  # ensure lhs, rhs are in same order (since labels may
  # not match between the two fits)
  lhs <- lhs[order(lhs[, 1]), ]
  rhs <- rhs[order(rhs[, 1]), ]
  expect_equivalent(lhs, rhs)
})

test_that("ml_kmeans() works properly", {
  sc <- testthat_spark_connection()
  iris_tbl <- testthat_tbl("iris")
  iris_kmeans <- ml_kmeans(iris_tbl, ~ . - Species, k = 5, seed = 11)
  rs <- ml_predict(iris_kmeans, iris_tbl) %>%
    dplyr::distinct(prediction) %>%
    dplyr::arrange(prediction) %>%
    dplyr::collect()

  expect_equal(rs$prediction, 0:4)
})

test_that("ml_compute_cost() for kmeans", {
  test_requires_version("2.0.0", "ml_compute_cost() requires Spark 2.0+")

  sc <- testthat_spark_connection()
  iris_tbl <- testthat_tbl("iris")
  iris_kmeans <- ml_kmeans(iris_tbl, ~ . - Species, k = 5, seed = 11)

  version <- spark_version(sc)

  if (version >= "3.0.0") {
    expect_error(ml_compute_cost(iris_kmeans, iris_tbl))
  } else {
    expect_equal(
      ml_compute_cost(iris_kmeans, iris_tbl),
      46.7123,
      tolerance = 0.01, scale = 1
    )
    expect_equal(
      iris_tbl %>%
        ft_r_formula(~ . - Species) %>%
        ml_compute_cost(iris_kmeans$model, .),
      46.7123,
      tolerance = 0.01, scale = 1
    )
  }
})

test_that("ml_compute_silhouette_measure() for kmeans", {
  test_requires_version("3.0.0", "ml_compute_silhouette_measure() requires Spark 2.0+")

  sc <- testthat_spark_connection()
  iris_tbl <- testthat_tbl("iris")
  iris_kmeans <- ml_kmeans(iris_tbl, ~ . - Species, k = 5, seed = 11)

  version <- spark_version(sc)

  expect_equal(
    ml_compute_silhouette_measure(iris_kmeans, iris_tbl),
    0.613,
    tolerance = 0.01, scale = 1
  )
  expect_equal(
    iris_tbl %>%
      ft_r_formula(~ . - Species) %>%
      ml_compute_silhouette_measure(iris_kmeans$model, .),
    0.613,
    tolerance = 0.01, scale = 1
  )
})

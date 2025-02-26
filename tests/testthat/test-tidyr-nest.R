skip_on_livy()
skip_on_arrow_devel()

sc <- testthat_spark_connection()
simple_sdf_1 <- testthat_tbl(
  name = "tidyr_nest_simple_sdf_1",
  data = tibble::tibble(x = c(1, 1, 1), y = 1:3)
)
simple_sdf_2 <- testthat_tbl(
  name = "tidyr_nest_simple_sdf_2",
  data = tibble::tibble(x = 1:3, y = c("B", "A", "A"))
)
mtcars_tbl <- testthat_tbl("mtcars")

test_that("nest turns grouped values into one list-df", {
  test_requires_version("2.0.0")

  expect_warning_on_arrow(
    out <- tidyr::nest(simple_sdf_1, data = y) %>% collect()
  )

  expect_equivalent(
    out,
    tibble::tibble(x = 1, data = list(lapply(seq(3), function(y) list(y = y))))
  )
})

test_that("nest uses grouping vars if present", {
  test_requires_version("2.0.0")

  out <- tidyr::nest(dplyr::group_by(simple_sdf_1, x))

  expect_equal(dplyr::group_vars(out), "x")

  expect_warning_on_arrow(
    o_c <- out %>%
      collect()
  )

  expect_equivalent(
    o_c,
    tibble::tibble(x = 1, data = list(lapply(seq(3), function(y) list(y = y))))
  )
})

test_that("provided grouping vars override grouped defaults", {
  test_requires_version("2.0.0")

  sdf <- copy_to(sc, tibble::tibble(x = 1, y = 2, z = 3)) %>% dplyr::group_by(x)
  out <- sdf %>% tidyr::nest(data = y)

  expect_equal(dplyr::group_vars(out), "x")
  expect_equivalent(
    expect_warning_on_arrow(out %>% collect()),
    tibble::tibble(x = 1, z = 3, data = list(list(y = 2)))
  )
})

test_that("no additional grouping var is created", {
  test_requires_version("2.0.0")

  mtcars_tbl_nested <- mtcars_tbl %>%
    dplyr::group_by(am) %>%
    tidyr::nest(perf = c(hp, mpg, disp, qsec))

  expect_equal(
    colnames(mtcars_tbl_nested),
    c("cyl", "drat", "wt", "vs", "am", "gear", "carb", "perf")
  )

  expect_equal(mtcars_tbl_nested %>% dplyr::group_vars(), "am")

  mtcars_tbl_nested <- mtcars_tbl %>%
    tidyr::nest(perf = c(hp, mpg, disp, qsec))

  expect_equal(
    colnames(mtcars_tbl_nested),
    c("cyl", "drat", "wt", "vs", "am", "gear", "carb", "perf")
  )
  expect_equal(mtcars_tbl_nested %>% dplyr::group_vars(), character())
})

test_that("puts data into the correct row", {
  test_requires_version("2.0.0")

  expect_warning_on_arrow(
    out <- tidyr::nest(simple_sdf_2, data = x) %>%
      dplyr::filter(y == "B") %>%
      collect()
  )

  expect_equivalent(
    out,
    tibble::tibble(y = "B", data = list(list(x = 1)))
  )
})

test_that("nesting everything", {
  test_requires_version("2.0.0")

  expect_warning_on_arrow(
    out <- tidyr::nest(simple_sdf_2, data = c(x, y)) %>% collect()
  )

  expect_equivalent(
    out,
    tibble::tibble(
      data = list(
        list(list(x = 1, y = "B"), list(x = 2, y = "A"), list(x = 3, y = "A"))
      )
    )
  )
})

test_that("can strip names", {
  test_requires_version("2.0.0")

  sdf <- copy_to(sc, tibble::tibble(x = c(1, 1, 1), ya = 1:3, yb = 4:6))

  expect_warning_on_arrow(
    out <- sdf %>%
      tidyr::nest(y = starts_with("y"), .names_sep = "") %>%
      collect()
  )


  expect_equivalent(
    out,
    tibble::tibble(
      x = 1,
      y = list(list(list(a = 1, b = 4), list(a = 2, b = 5), list(a = 3, b = 6)))
    )
  )
})

test_that("nesting works for empty data frames", {
  test_requires_version("2.0.0")

  sdf <- copy_to(sc, tibble::tibble(x = integer(), y = character()))

  expect_warning_on_arrow(
    out <- tidyr::nest(sdf, data = x) %>% collect()
  )

  expect_named(out, c("y", "data"))
  expect_equal(nrow(out), 0L)

  expect_warning_on_arrow(
    out <- tidyr::nest(sdf, data = c(x, y)) %>% collect()
  )

  expect_named(out, "data")
  expect_equivalent(out, tibble::tibble(data = list(NA)))
})

test_that("can nest multiple columns", {
  test_requires_version("2.0.0")

  sdf <- copy_to(sc, tibble::tibble(x = 1, a1 = 1, a2 = 2, b1 = 1, b2 = 2))

  expect_warning_on_arrow(
    out <- sdf %>%
      tidyr::nest(a = c(a1, a2), b = c(b1, b2)) %>%
      collect()
  )

  expect_equivalent(
    out,
    tibble::tibble(
      x = 1,
      a = list(list(list(a1 = 1, a2 = 2))),
      b = list(list(list(b1 = 1, b2 = 2)))
    )
  )
})

test_that("nesting no columns nests all inputs", {
  test_requires_version("2.0.0")

  # included only for backward compatibility
  sdf <- copy_to(sc, tibble::tibble(a1 = 1, a2 = 2, b1 = 1, b2 = 2))

  expect_warning(out <- tidyr::nest(sdf), "must not be empty")

  expect_equivalent(
    expect_warning_on_arrow(out %>% collect()),
    tibble::tibble(
      data = list(list(list(a1 = 1, a2 = 2, b1 = 1, b2 = 2)))
    )
  )
})

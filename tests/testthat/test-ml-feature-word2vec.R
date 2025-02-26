skip_on_livy()
skip_on_arrow_devel()

skip_databricks_connect()
test_that("ft_word2vec() default params", {
  test_requires_version("3.0.0")
  sc <- testthat_spark_connection()
  test_default_args(sc, ft_word2vec)
})

test_that("ft_word2vec() param setting", {
  test_requires_version("3.0.0")
  sc <- testthat_spark_connection()
  test_args <- list(
    input_col = "foo",
    output_col = "bar",
    vector_size = 90,
    min_count = 4,
    max_sentence_length = 1100,
    num_partitions = 2,
    step_size = 0.04,
    max_iter = 2,
    seed = 94
  )
  test_param_setting(sc, ft_word2vec, test_args)
})

test_that("ft_word2vec() returns result with correct length", {
  sc <- testthat_spark_connection()
  sentence_df <- data.frame(
    sentence = c(
      "Hi I heard about Spark",
      "I wish Java could use case classes",
      "Logistic regression models are neat"
    )
  )
  sentence_tbl <- sdf_copy_to(sc, sentence_df, overwrite = TRUE)
  tokenized_tbl <- ft_tokenizer(sentence_tbl, "sentence", "words") %>%
    sdf_register("tokenized")

  expect_warning_on_arrow(
    result <- tokenized_tbl %>%
      ft_word2vec("words", "result", vector_size = 3, min_count = 0) %>%
      pull(result)
  )

  expect_equal(sapply(result, length), c(3, 3, 3))
})

test_that("ml_find_synonyms works properly", {
  # NOTE: this test case is functionally identical to the one in
  # https://github.com/apache/spark/blob/87b93d32a6bfb0f2127019b97b3fc1d13e16a10b/mllib/src/test/scala/org/apache/spark/mllib/feature/Word2VecSuite.scala#L37
  test_requires_version("2.0.0", "spark computation different in 1.6.x")
  sc <- testthat_spark_connection()
  sentence <- data.frame(sentence = do.call(paste, as.list(c(rep("a b", 100), rep("a c", 10)))))
  doc <- rbind(sentence, sentence)
  sdf <- sdf_copy_to(sc, doc, overwrite = TRUE)
  tokenized_tbl <- ft_tokenizer(sdf, "sentence", "words")

  model <- ft_word2vec(sc, "words", "result", vector_size = 10, seed = 42L, min_count = 0) %>%
    ml_fit(tokenized_tbl)

  synonyms <- ml_find_synonyms(model, "a", 2) %>% pull(word)

  # synonym-wise "b" should be closer to "a" than "c" is
  expect_equal(synonyms, c("b", "c"))
})

# Unit tests for utility functions

library(testthat)

test_that("generate_pay_period works correctly", {
  result <- generate_pay_period("2025-07-28")
  
  expect_equal(length(result$dates), 14)
  expect_equal(result$start_date, as.Date("2025-07-28"))
  expect_equal(result$end_date, as.Date("2025-08-10"))
  expect_equal(length(result$week1), 7)
  expect_equal(length(result$week2), 7)
})

test_that("validate_status_code works correctly", {
  expect_true(validate_status_code("AL"))
  expect_true(validate_status_code("AWS"))
  expect_true(validate_status_code(""))
  expect_true(validate_status_code(NA))
  expect_false(validate_status_code("INVALID"))
})

test_that("format_work_schedule cleans input", {
  expect_equal(format_work_schedule("  MF / 8-5:30  "), "MF / 8-5:30")
  expect_equal(format_work_schedule(""), "Standard")
  expect_equal(format_work_schedule(NA), "Standard")
})
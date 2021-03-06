context("key for tsibble")

test_that("unkey()", {
  expect_error(unkey(pedestrian))
  sx <- pedestrian %>% filter(Sensor == "Southern Cross Station")
  expect_equal(key_vars(unkey(sx)), "NULL")
  unkey_sx <- unkey(sx) %>% unkey()
  expect_equal(key_vars(unkey_sx), "NULL")
})

test_that("key_rename()", {
  bm <- pedestrian %>% 
    filter(Sensor == "Birrarung Marr") %>% 
    unkey()
  key_bm <- key_rename(bm, "sensor" = "Sensor")
  expect_equal(key_vars(key_bm), "NULL")
  expect_true("Sensor" %in% names(key_bm))
  key_t <- tourism %>% 
    key_rename("purpose" = "Purpose", "region" = "Region", "trip" = "Trip")
  expect_equal(key_flatten(key(key_t)), c("region", "State", "purpose"))
})

test_that("key_reduce()", {
  melb <- tourism %>% 
    filter(Region == "Melbourne")
  expect_error(melb %>% select(-Purpose), "Invalid")
  key_m <- melb %>% 
    select(-Region, -State)
  expect_equal(key_flatten(key(key_m)), "Purpose")
})

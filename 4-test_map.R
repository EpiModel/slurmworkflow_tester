library(future.apply)
plan(multicore, workers = ncores)

future_lapply(seq_len(ncores), function(i) {
  msg <- paste0(
    "On core: ", i, "\n",
    "iterator1: ", iterator1, "\n",
    "iterator2: ", iterator2, "\n",
    "var1 = ", var1, ", var2 = ", var2, "\n\n"
  )
  cat(msg)
})

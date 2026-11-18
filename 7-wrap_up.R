# Check that every planned item of the calibration-like loop ran exactly once.
#   `sizes`: the map size of each iteration (passed by the workflow)
calib_dir <- file.path(Sys.getenv("SWF_RUN_DIR"), "calib")
done <- sort(list.files(calib_dir, pattern = "^iter[0-9]+_item[0-9]+$"))
expected <- sort(unlist(lapply(seq_along(sizes), function(i) {
  if (sizes[i] > 0) paste0("iter", i, "_item", seq_len(sizes[i]))
})))

cat("Items run per iteration:\n")
print(table(sub("_item.*", "", done)))

missing <- setdiff(expected, done)
extra <- setdiff(done, expected)
if (length(missing) > 0 || length(extra) > 0) {
  stop(
    "Loop check FAILED. Missing: ", paste(missing, collapse = ", "),
    "; unexpected: ", paste(extra, collapse = ", ")
  )
}
cat("Loop check OK:", length(done), "items over", length(sizes), "iterations\n")

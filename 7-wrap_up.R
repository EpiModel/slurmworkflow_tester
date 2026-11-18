# Check that every planned item ran exactly once, and that the two steps that
# fail on purpose (`fail_continue`, `timeout_kill`) left their markers.
#   `sizes`: the map size of each iteration (passed by the workflow)
run_dir <- Sys.getenv("SWF_RUN_DIR")
calib_dir <- file.path(run_dir, "calib")
done <- sort(list.files(calib_dir, pattern = "^iter[0-9]+_item[0-9]+$"))
expected <- sort(unlist(lapply(seq_along(sizes), function(i) {
  if (sizes[i] > 0) paste0("iter", i, "_item", seq_len(sizes[i]))
})))

cat("Items run per iteration:\n")
print(table(sub("_item.*", "", done)))

problems <- character()
missing <- setdiff(expected, done)
extra <- setdiff(done, expected)
if (length(missing) > 0 || length(extra) > 0) {
  problems <- c(problems, paste0(
    "loop: missing ", paste(missing, collapse = ", "),
    "; unexpected ", paste(extra, collapse = ", ")
  ))
}

markers <- list.files(file.path(run_dir, "failed"))
codes <- vapply(
  markers,
  function(m) readLines(file.path(run_dir, "failed", m))[1],
  character(1)
)
cat("\nFailure markers:\n")
print(codes)
if (length(markers) != 2) {
  problems <- c(problems, paste0("expected 2 failure markers, got ", length(markers)))
}
if (sum(grepl("_1$", markers) & codes == "1") != 1) {
  problems <- c(problems, "no marker with code 1 for task 1 of `fail_continue`")
}
if (sum(codes == "143") != 1) {
  problems <- c(problems, "no marker with code 143 (SIGTERM) for `timeout_kill`")
}

if (length(problems) > 0) {
  stop("Checks FAILED:\n  ", paste(problems, collapse = "\n  "))
}
cat(
  "Loop check OK:", length(done), "items over", length(sizes), "iterations\n",
  "Failure check OK: 2 markers (codes 1 and 143)\n"
)

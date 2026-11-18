# Plays the role of `swfcalib::calibration_step1`: decide what the next wave
# runs, or end the loop.
#   `sizes`: the map size of each iteration (passed by the workflow)
calib_dir <- file.path(Sys.getenv("SWF_RUN_DIR"), "calib")
dir.create(calib_dir, showWarnings = FALSE)
iter_file <- file.path(calib_dir, "iteration")
iter <- if (file.exists(iter_file)) as.integer(readLines(iter_file)) + 1L else 1L
writeLines(as.character(iter), iter_file)

if (iter > length(sizes)) {
  cat("Loop done after", iter - 1, "iterations\n")
  slurmworkflow::change_next_workflow_step("wrap_up")
} else {
  cat("Iteration", iter, ": the next `calib_work` runs", sizes[iter], "items\n")
  # 0 items skips `calib_work` and comes straight back here
  slurmworkflow::set_map_size("calib_work", sizes[iter])
}

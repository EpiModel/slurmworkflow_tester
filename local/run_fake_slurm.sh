#!/bin/bash
# Dry run of the tester workflows on this computer, with the fake Slurm shipped
# in slurmworkflow's sources (tests/fake_slurm). Run it from the project root,
# with R and the project's renv available:
#
#   bash local/run_fake_slurm.sh [path to a slurmworkflow checkout]
#
# The `setup` step (git pull and renv on the HPC) is skipped: the main run
# starts at `rscript`. Exit status 0 when both workflows behaved as expected.
set -euo pipefail

if [[ ! -f 1-make_workflow.R ]]; then
  echo "Run this script from the root of the tester project." >&2
  exit 1
fi

SWF_REPO="$(realpath "${1:-../slurmworkflow}")"
if [[ ! -x "$SWF_REPO/tests/fake_slurm/sbatch" ]]; then
  echo "No fake Slurm in $SWF_REPO/tests/fake_slurm" >&2
  exit 1
fi

export PATH="$SWF_REPO/tests/fake_slurm:$PATH"
export FAKE_SLURM_DIR="$PWD/local/fake_slurm_state"
rm -rf "$FAKE_SLURM_DIR"
mkdir -p "$FAKE_SLURM_DIR"

export SWF_TESTER_LOCAL=true
Rscript 1-make_workflow.R
Rscript 8-make_failstop_workflow.R

fail() { echo "FAILED: $*" >&2; exit 1; }

# Main workflow -----------------------------------------------------------------
WF=workflows/test_slurmworkflow_local
"$WF/swf" steps
run_id="$("$WF/swf" start -s rscript)"
echo "Started run $run_id"
fake_slurm_run
"$WF/swf" status
grep -q "event=end" "$WF/swf.d/run/$run_id/history" ||
  fail "the main workflow did not reach its end"
"$WF/swf" log -s wrap_up -n 100 | grep -q "Failure check OK" ||
  fail "wrap_up did not pass"

# Failure stops the workflow ----------------------------------------------------
WF2=workflows/test_slurmworkflow_local_failstop
run2="$("$WF2/swf" start)"
fake_slurm_run
"$WF2/swf" status || true
grep -q "event=error.*reason=step_failed:1_boom" "$WF2/swf.d/run/$run2/history" ||
  fail "the failstop workflow did not stop on boom"
[[ ! -e "$WF2/swf.d/run/$run2/never_ran" ]] ||
  fail "the step after a failure ran"

echo "Local dry run OK"

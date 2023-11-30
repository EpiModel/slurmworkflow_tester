# Test Workflow for `slurmworkflow`

This repo creates a workflow testing
[`slurmworkflow`](https://github.com/EpiModel/slurmworkflow)'s capabilities on
an HPC.

## How To Use

- Create a new GitHub repository by clicking the green `Use this template` button above.
- Clone this new repo on your computer AND on the HPC
- On your local computer:
  - Edit the "0-settings.R" script according to your setup
  - Commit your changes and push to GitHub
  - Run the script "1-make_workflow.R"

Send the generated workflow directory "workflows/test_slurmworkflow" to the HPC with:

*for Windows users: *

```sh
# bash - local (for WINDOWS users)
set DISPLAY=
scp -r workflows\test_slurmworkflow <user>@<hpc address>:<path_to_project_on_HPC>/workflows/
```

*for Linux / MacOS users *

```sh
# bash - local (for Linux / MacOS users)
scp -r workflows/test_slurmworkflow <user>@<hpc address>:<path_to_project_on_HPC>/workflows/
```

- On the HPC
  - `cd` into your project directory
  - execute the workflow with:

```sh
# bash - HPC
./workflows/test_slurmworkflow/start_workflow.sh
```

*Note:
If you are a Windows user, the script may not be executable. You can solve it with the following command:*

```sh
# bash - hpc
chmod +x workflows/test_slurmworkflow/start_workflow.sh
```

*The workflow will not work if you source the file (with `source <script>` or `. <script>`).*

## Expected results

If all goes well, you should receive an e-mail a few minutes later with object looking like:

`[External] Slurm Job_id=14940582 Name=test_slurmworkflow_step5 Ended, Run time 00:00:02, COMPLETED, ExitCode 0`

If the `ExitCode` is anything other than `0`, it means it failed.

On the HPC you can run `ls workflows/test_slurmworkflow/log/`. The folder should contain:
- 1 "test_slurmworkflow_controler.out" file
- 1 "test_slurmworkflow_step1_xxx_xxx.out" file
- 1 "test_slurmworkflow_step2_xxx_xxx.out" file
- 2 "test_slurmworkflow_step3_xxx_xxx.out" file
- 5 "test_slurmworkflow_step4_xxx_xxx.out" file
- 1 "test_slurmworkflow_step5_xxx_xxx.out" file

If so: SUCCESS! `slurmworkflow` is working correctly

The playbooks in this directory can be used to deploy, and gracefully unmanage
and remanage self hosted github runners.

To unmanage, run the go script in the parent dir targeting the disable/enable
playbooks, using --limit to limit to specific machines if required, e.g:

`./go -p gha-runners/disable.yml -i github-actions -g all --limit gha-runner-21,gha-runner-22`

Then when maintenance is complete:

`./go -p gha-runners/enable.yml -i github-actions -g all --limit gha-runner-21,gha-runner-22`

The update-labels.yml playbook can be used to replace the custom runner
labels on all runners. It will add a labels corresponding to the VM's IP
and hostname. This one requires specifying `-e gha_api_token=xxxx` to
provide a GitHub API token with Org access. You may also specify `-e
gha_runner_labels=xxx,yyy` to apply additional fixed labels; for the
current Capella self-hosted runners, this should be `build-and-deliver`.

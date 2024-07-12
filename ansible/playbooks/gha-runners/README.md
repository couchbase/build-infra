The playbooks in this directory can be used to deploy, and gracefully unmanage
and remanage self hosted github runners.

To unmanage, run the go script in the parent dir targeting the disable/enable
playbooks, using --limit to limit to specific machines if required, e.g:

`./go -p gha-runners/disable.yml -i github-actions -g all --limit gha-runner-21,gha-runner-22`

Then when maintenance is complete:

`./go -p gha-runners/enable.yml -i github-actions -g all --limit gha-runner-21,gha-runner-22`

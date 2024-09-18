Sets up a Linux host as a GitHub Actions self-hosted runner.

Required Ansible variables:

  - `gha_org` - The github org

  - `gha_api_token` - A GitHub Personal Authorization Token with (gulp) org:admin
    and repo privileges

  - `gha_runner_group` - The name of the runner group at the org level to add the
    runner to.

Options Ansible variables:

  - `gha_runner_labels` - Comma-separated list of extra labels to assign to the
    runner. Default is empty.

  - `gha_runner_name` - The name to give to this runner. All runners must
    have a unique name. Will default to `vm_name` if set (which is used
    by the create-ubuntu-agent script), or else `inventory_hostname`.

Note: This role requires that the runner be added to a non-default runner group.
Since those can only be defined at the org level, we only support adding runners
at the org level.

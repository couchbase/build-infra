Sets up a Linux host as a CircleCI self-hosted runner.

Required Ansible variables:

 - circleci_auth_token - The auth token associated with the CircleCI
   Resource Class, as documented here:
   https://circleci.com/docs/runner-installation

- circleci_runner_name - The name to give to this runner. All runners
  must have a unique name. Will default to the value of `inventory_hostname`.

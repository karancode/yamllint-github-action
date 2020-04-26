# yamllint-github-action

Yamllint GitHub Actions allow you to execute `yamllint` command within GitHub Actions.

The output of the actions can be viewed from the Actions tab in the main repository view. If the actions are executed on a pull request event, a comment may be posted on the pull request.

Yamllint GitHub Actions is a single GitHub Action that can be executed on different directories depending on the content of the GitHub Actions YAML file.

## Success Criteria

An exit code of `0` is considered a successful execution.

## Usage

The most common usage is to run `yamllint` on a file/directory. A comment will be posted to the pull request depending on the output of the Yamllint command being executed. This workflow can be configured by adding the following content to the GitHub Actions workflow YAML file.

```yaml
name: 'Yamllint GitHub Actions'
on:
  - pull_request
jobs:
  yamllint:
    name: 'Yamllint'
    runs-on: ubuntu-latest
    steps:
      - name: 'Checkout'
        uses: actions/checkout@master
      - name: 'Yamllint'
        uses: karancode/yamllint-github-action@master
        with:
          yamllint_file_or_dir: '<yaml_file_or_dir>'
          yamllint_strict: false
          yamllint_comment: true
        env:
          GITHUB_ACCESS_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

This was a simplified example showing the basic features of this Yamllint GitHub Actions.

## Inputs

Inputs configure Yamllint GitHub Actions to perform lint action.

| Parameter                    | Default | Description                                                                                                               |
|------------------------------|---------|---------------------------------------------------------------------------------------------------------|
| `yamllint_file_or_dir`       | .       | (Optional) The file or directory to run `yamllint` on (assumes that the directory contains *.yaml file) |
| `yamllint_strict`            | `false` | (Optional) Yamllint strict option.                                  |
| `yamllint_config_filepath`   | `empty` | (Optional) Path to a custom config file.                            |
| `yamllint_config_datapath`   | `empty` | (Optional) Custom configuration (as YAML source).                   |
| `yamllint_format`            | `auto`  | (Optional) Format for parsing.                                      |
| `yamllint_comment`           | `false` | (Optional) Comment on GitHub pull requests, possible are true,false |

## Outputs

Outputs are used to pass information to subsequent GitHub Actions steps.

* `yamllint_output` - The Yamllint build outputs.

## Secrets

Secrets are similar to inputs except that they are encrypted and only used by GitHub Actions. It's a convenient way to keep sensitive data out of the GitHub Actions workflow YAML file.

* `GITHUB_ACCESS_TOKEN` - (Optional) The GitHub API token used to post comments to pull requests. Not required if the `yamllint_comment` input is set to `false`.

## Development

### Testing

For testing the [bats](https://github.com/bats-core/bats-core) testing framework is used.
Tests can be run with ``./tests/run.bats`` but first you need to install [bats](https://github.com/bats-core/bats-core#installation).

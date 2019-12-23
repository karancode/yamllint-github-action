#!/bin/sh

function yaml_lint {

    # gather output
    echo "lint: info: yamllint on ${yamllint_file_or_dir}."
    lint_output=$(yamllint ${yamllint_strict} ${yamllint_config_filepath} ${yamllint_config_datapath} ${yamllint_format} ${yamllint_file_or_dir})
    lint_exit_code=${?}

    # exit code 0 - success
    if [ ${lint_exit_code} -eq 0 ];then
        lint_comment_status="Success"
        echo "lint: info: successful yamllint on ${yamllint_file_or_dir}."
        echo "${lint_output}"
        echo
    fi

    # exit code !0 - failure
    if [ ${lint_exit_code} -ne 0 ]; then
        lint_comment_status="Failed"
        echo "lint: error: failed yamllint on ${yamllint_file_or_dir}."
        echo "${lint_output}"
        echo
    fi

    # comment
    if [ "${GITHUB_EVENT_NAME}" == "pull_request" ] && [ "${yamllint_comment}" == "1" ]; then
        lint_comment_wrapper="#### \`yammlint \` ${lint_comment_status}
<details><summary>Show Output</summary>
\`\`\`
${lint_output}
 \`\`\`
</details>
*Workflow: \`${GITHUB_WORKFLOW}\`, Action: \`${GITHUB_ACTION}\`, Lint: \`${yamllint_file_or_dir}\`*"
    
        echo "lint: info: creating json"
        lint_payload=$(echo "${lint_comment_wrapper}" | jq -R --slurp '{body: .}')
        lint_comment_url=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.comments_url)
        echo "lint: info: commenting on the pull request"
        echo "${lint_payload}" | curl -s -S -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" --header "Content-Type: application/json" --data @- "${lint_comment_url}" > /dev/null
    fi

    echo ::set-output name=yamllint_output::${lint_output}
    exit ${lint_exit_code}
}


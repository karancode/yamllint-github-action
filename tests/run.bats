#!/usr/bin/env bats

# NOTE: environment variable GITHUB_EVENT_PATH
# is required in a pullrequest scenario. If the variable
# is not set the test is gonna hang.

# global variables ############################################################
CONTAINER_NAME="yamllint-github-action"

# build container to test the behavior ########################################
@test "build container" {
  docker build -t $CONTAINER_NAME . >&2
}

# functions ###################################################################
debug() {
  status="$1"
  output="$2"
  if [[ ! "${status}" -eq "0" ]]; then
  echo "status: ${status}"
  echo "output: ${output}"
  fi
}

###############################################################################
## test cases #################################################################
###############################################################################

function setup() {
  unset INPUT_YAMLLINT_FILE_OR_DIR
  unset INPUT_YAMLLINT_STRICT
  unset INPUT_YAMLLINT_CONFIG_FILEPATH
  unset INPUT_YAMLLINT_CONFIG_DATAPATH
  unset INPUT_YAMLLINT_FORMAT
  unset INPUT_YAMLLINT_COMMENT
  export ROOT_DIR="${ROOT_DIR:-$(pwd)}"
  export GITHUB_OUTPUT_FILE="${GITHUB_OUTPUT_FILE:-$(mktemp -p "${BATS_TMPDIR}")}"
  cp /dev/null "${GITHUB_OUTPUT_FILE}"
}

## INPUT_YAMLLINT_FILE_OR_DIR #################################################
###############################################################################

## File
@test "INPUT_YAMLLINT_FILE_OR_DIR: valid single without warnings or errors" {
  INPUT_YAMLLINT_FILE_OR_DIR="/mnt/tests/data/single_files/file2.yml"

  run docker run --rm \
  -v "${ROOT_DIR}:/mnt/" \
  -e INPUT_YAMLLINT_FILE_OR_DIR="${INPUT_YAMLLINT_FILE_OR_DIR}" \
  --mount type=bind,source="${GITHUB_OUTPUT_FILE}",target=/github_output \
  -e GITHUB_OUTPUT=/github_output \
  -i $CONTAINER_NAME

  debug "${status}" "${output}" "${lines}"
  echo $output | grep -q "lint: info: successful yamllint on ${INPUT_YAMLLINT_FILE_OR_DIR}."
  [[ "${status}" -eq 0 ]]
}

@test "INPUT_YAMLLINT_FILE_OR_DIR: valid single with one errors" {
  INPUT_YAMLLINT_FILE_OR_DIR="/mnt/tests/data/single_files/file1.yml"

  run docker run --rm \
  -v "${ROOT_DIR}:/mnt/" \
  -e INPUT_YAMLLINT_FILE_OR_DIR="${INPUT_YAMLLINT_FILE_OR_DIR}" \
  --mount type=bind,source="${GITHUB_OUTPUT_FILE}",target=/github_output \
  -e GITHUB_OUTPUT=/github_output \
  -i $CONTAINER_NAME

  debug "${status}" "${output}" "${lines}"

  echo $output | grep -q "$INPUT_YAMLLINT_FILE_OR_DIR"
  echo $output | grep -q "lint: error: failed yamllint on"
  echo $output | grep -q "line too long (114 > 80 characters)"

  cat ${GITHUB_OUTPUT_FILE} | grep -q -Pzo "yamllint_output<<EOF\n$INPUT_YAMLLINT_FILE_OR_DIR"

  [[ "${status}" -eq 1 ]]
}

## folder
@test "INPUT_YAMLLINT_FILE_OR_DIR: nested_folder with one errors" {
  run docker run --rm \
  -v "${ROOT_DIR}:/mnt/" \
  -e INPUT_YAMLLINT_FILE_OR_DIR="/mnt/tests/data/nested_folder" \
  --mount type=bind,source="${GITHUB_OUTPUT_FILE}",target=/github_output \
  -e GITHUB_OUTPUT=/github_output \
  -i $CONTAINER_NAME

  debug "${status}" "${output}" "${lines}"

  echo $output | grep -q "$INPUT_YAMLLINT_FILE_OR_DIR"
  echo $output | grep -q "lint: error: failed yamllint on"
  echo $output | grep -q "line too long (115 > 80 characters)"
  [[ "${status}" -eq 1 ]]
}

## INPUT_YAMLLINT_COMMENT #################################################
###############################################################################

### enabled (1,true)
@test "INPUT_YAMLLINT_COMMENT: set 1 in PR scenario with lint errors" {
  INPUT_YAMLLINT_FILE_OR_DIR="/mnt/tests/data/single_files/file1.yml"

  run docker run --rm \
  -v "${ROOT_DIR}:/mnt/" \
  -e INPUT_YAMLLINT_FILE_OR_DIR="${INPUT_YAMLLINT_FILE_OR_DIR}" \
  -e INPUT_YAMLLINT_COMMENT="1" \
  -e GITHUB_EVENT_PATH="/tmp/" \
  -e GITHUB_EVENT_NAME="pull_request" \
  --mount type=bind,source="${GITHUB_OUTPUT_FILE}",target=/github_output \
  -e GITHUB_OUTPUT=/github_output \
  -i $CONTAINER_NAME

  debug "${status}" "${output}" "${lines}"

  echo $output | grep -q "$INPUT_YAMLLINT_FILE_OR_DIR"
  echo $output | grep -q "line too long (114 > 80 characters)"
  echo $output | grep -q "lint: info: commenting on the pull request"

  cat ${GITHUB_OUTPUT_FILE} | grep -q -Pzo "yamllint_output<<EOF\n$INPUT_YAMLLINT_FILE_OR_DIR"

  [[ "${status}" -eq 1 ]]
}

@test "INPUT_YAMLLINT_COMMENT: set true in PR scenario with lint errors" {
  INPUT_YAMLLINT_FILE_OR_DIR="/mnt/tests/data/single_files/file1.yml"

  run docker run --rm \
  -v "${ROOT_DIR}:/mnt/" \
  -e INPUT_YAMLLINT_FILE_OR_DIR="${INPUT_YAMLLINT_FILE_OR_DIR}" \
  -e INPUT_YAMLLINT_COMMENT="true" \
  -e GITHUB_EVENT_PATH="/tmp/" \
  -e GITHUB_EVENT_NAME="pull_request" \
  --mount type=bind,source="${GITHUB_OUTPUT_FILE}",target=/github_output \
  -e GITHUB_OUTPUT=/github_output \
  -i $CONTAINER_NAME

  debug "${status}" "${output}" "${lines}"

  echo $output | grep -q "$INPUT_YAMLLINT_FILE_OR_DIR"
  echo $output | grep -q "line too long (114 > 80 characters)"
  echo $output | grep -q "lint: info: commenting on the pull request"

  cat ${GITHUB_OUTPUT_FILE} | grep -q -Pzo "yamllint_output<<EOF\n$INPUT_YAMLLINT_FILE_OR_DIR"

  [[ "${status}" -eq 1 ]]
}

@test "INPUT_YAMLLINT_COMMENT: set true in PR scenario without lint errors" {
  INPUT_YAMLLINT_FILE_OR_DIR="/mnt/tests/data/single_files/file2.yml"

  run docker run --rm \
  -v "${ROOT_DIR}:/mnt/" \
  -e INPUT_YAMLLINT_FILE_OR_DIR="${INPUT_YAMLLINT_FILE_OR_DIR}" \
  -e INPUT_YAMLLINT_COMMENT="true" \
  -e GITHUB_EVENT_PATH="/tmp/" \
  -e GITHUB_EVENT_NAME="pull_request" \
  --mount type=bind,source="${GITHUB_OUTPUT_FILE}",target=/github_output \
  -e GITHUB_OUTPUT=/github_output \
  -i $CONTAINER_NAME

  debug "${status}" "${output}" "${lines}"

  echo $output | grep -q "$INPUT_YAMLLINT_FILE_OR_DIR"
  echo $output | grep -vq "lint: info: commenting on the pull request"

  cat ${GITHUB_OUTPUT_FILE} | grep -vq -Pzo "yamllint_output<<EOF\n$INPUT_YAMLLINT_FILE_OR_DIR"

  [[ "${status}" -eq 0 ]]
}

### disabled (0,false)
@test "INPUT_YAMLLINT_COMMENT: set 0 in PR scenario with lint errors" {
  INPUT_YAMLLINT_FILE_OR_DIR="/mnt/tests/data/single_files/file1.yml"

  run docker run --rm \
  -v "${ROOT_DIR}:/mnt/" \
  -e INPUT_YAMLLINT_FILE_OR_DIR="${INPUT_YAMLLINT_FILE_OR_DIR}" \
  -e INPUT_YAMLLINT_COMMENT="0" \
  -e GITHUB_EVENT_PATH="/tmp/" \
  -e GITHUB_EVENT_NAME="pull_request" \
  --mount type=bind,source="${GITHUB_OUTPUT_FILE}",target=/github_output \
  -e GITHUB_OUTPUT=/github_output \
  -i $CONTAINER_NAME

  debug "${status}" "${output}" "${lines}"

  echo $output | grep -q "$INPUT_YAMLLINT_FILE_OR_DIR"
  echo $output | grep -q "line too long (114 > 80 characters)"
  echo $output | grep -vq "lint: info: commenting on the pull request"

  cat ${GITHUB_OUTPUT_FILE} | grep -q -Pzo "yamllint_output<<EOF\n$INPUT_YAMLLINT_FILE_OR_DIR"

  [[ "${status}" -eq 1 ]]
}

@test "INPUT_YAMLLINT_COMMENT: set false in PR scenario with lint errors" {
  INPUT_YAMLLINT_FILE_OR_DIR="/mnt/tests/data/single_files/file1.yml"

  run docker run --rm \
  -v "${ROOT_DIR}:/mnt/" \
  -e INPUT_YAMLLINT_FILE_OR_DIR="${INPUT_YAMLLINT_FILE_OR_DIR}" \
  -e INPUT_YAMLLINT_COMMENT="false" \
  -e GITHUB_EVENT_PATH="/tmp/" \
  -e GITHUB_EVENT_NAME="pull_request" \
  --mount type=bind,source="${GITHUB_OUTPUT_FILE}",target=/github_output \
  -e GITHUB_OUTPUT=/github_output \
  -i $CONTAINER_NAME

  debug "${status}" "${output}" "${lines}"

  echo $output | grep -q "$INPUT_YAMLLINT_FILE_OR_DIR"
  echo $output | grep -q "line too long (114 > 80 characters)"
  echo $output | grep -vq "lint: info: commenting on the pull request"

  cat ${GITHUB_OUTPUT_FILE} | grep -q -Pzo "yamllint_output<<EOF\n$INPUT_YAMLLINT_FILE_OR_DIR"

  [[ "${status}" -eq 1 ]]
}

### disabled (empty,notset)
@test "INPUT_YAMLLINT_COMMENT: set empty in PR scenario with lint errors" {
  INPUT_YAMLLINT_FILE_OR_DIR="/mnt/tests/data/single_files/file1.yml"

  run docker run --rm \
  -v "${ROOT_DIR}:/mnt/" \
  -e INPUT_YAMLLINT_FILE_OR_DIR="${INPUT_YAMLLINT_FILE_OR_DIR}" \
  -e INPUT_YAMLLINT_COMMENT="" \
  -e GITHUB_EVENT_PATH="/tmp/" \
  -e GITHUB_EVENT_NAME="pull_request" \
  --mount type=bind,source="${GITHUB_OUTPUT_FILE}",target=/github_output \
  -e GITHUB_OUTPUT=/github_output \
  -i $CONTAINER_NAME

  debug "${status}" "${output}" "${lines}"

  echo $output | grep -q "$INPUT_YAMLLINT_FILE_OR_DIR"
  echo $output | grep -q "line too long (114 > 80 characters)"
  echo $output | grep -vq "lint: info: commenting on the pull request"

  cat ${GITHUB_OUTPUT_FILE} | grep -q -Pzo "yamllint_output<<EOF\n$INPUT_YAMLLINT_FILE_OR_DIR"

  [[ "${status}" -eq 1 ]]
}

@test "INPUT_YAMLLINT_COMMENT: not set in PR scenario with lint errors" {
  INPUT_YAMLLINT_FILE_OR_DIR="/mnt/tests/data/single_files/file1.yml"

  run docker run --rm \
  -v "${ROOT_DIR}:/mnt/" \
  -e INPUT_YAMLLINT_FILE_OR_DIR="${INPUT_YAMLLINT_FILE_OR_DIR}" \
  -e GITHUB_EVENT_PATH="/tmp/" \
  -e GITHUB_EVENT_NAME="pull_request" \
  --mount type=bind,source="${GITHUB_OUTPUT_FILE}",target=/github_output \
  -e GITHUB_OUTPUT=/github_output \
  -i $CONTAINER_NAME

  debug "${status}" "${output}" "${lines}"

  echo $output | grep -q "$INPUT_YAMLLINT_FILE_OR_DIR"
  echo $output | grep -q "line too long (114 > 80 characters)"
  echo $output | grep -vq "lint: info: commenting on the pull request"

  cat ${GITHUB_OUTPUT_FILE} | grep -q -Pzo "yamllint_output<<EOF\n$INPUT_YAMLLINT_FILE_OR_DIR"

  [[ "${status}" -eq 1 ]]
}

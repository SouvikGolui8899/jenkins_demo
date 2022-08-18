#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
THIS="${BASH_SOURCE[0]##*/}"

JENKINS_HOST_IP="172.31.32.33"
JENKINS_HOST_PORT="9000"
JENKINS_HOST_URL="http://${JENKINS_HOST_IP}:${JENKINS_HOST_PORT}/"
JENKINS_CMD_PREFIX="java -jar ${HOME}/jenkins-cli.jar -s ${JENKINS_HOST_URL} -webSocket"

HOST="172.31.1.117"
GPUDB_USER="admin"
GPUDB_PASSWORD='Kinetica1!'
TESTMGR_USER='admin'
TESTMGR_PASSWORD='Kinetica1!'
REMOTE_GPUDB_HOME="/home/gpudb"
PROJECT_DIR="${REMOTE_GPUDB_HOME}/jenkins_test"
SEQUENTIAL_PROJECT_NAME="gadmin-$(basename "$( cd "${SCRIPT_DIR}/../" && pwd)")"
PARALLEL_PROJECT_NAME="${SEQUENTIAL_PROJECT_NAME}-parallel"
SEQUENTIAL_JENKINS_JOB_CONFIG="${SCRIPT_DIR}/job-config.xml"
PARALLEL_JENKINS_JOB_CONFIG="${SCRIPT_DIR}/job-config-parallel.xml"

SEQUENTIAL=0
PARALLEL=0

BUILD_NAME='7.1.7.2.20220709195204'

#echo "${JENKINS_HOST_URL} :: ${JENKINS_CMD_PREFIX} :: ${PROJECT_NAME} :: ${JENKINS_JOB_CONFIG}"

function options_menu(){
    HELP_STR="""
      Program: ${THIS}

      Description:
          This script runs QE Jenkins Pipeline.

      ./bin/${THIS} [--sequential|--parallel] [--gpudb HOST] [--user USER] [--password PASSWORD] [--tuser USER] [--tpwd PASSWORD] [--project-dir '${PROJECT_DIR}'] [--help]

          Options:
              --gpudb                             : Specify GPUdb host
                                                        Default: ${HOST}
                                                        e.g. - 172.xx.xx.xx
                                                        e.g. - 172.xx.xx.xx,172.yy.yy.yy
              --user USER                         : Specify GPUdb userID
                                                        Default: ${GPUDB_USER}
              --password PASSWORD                 : Specify password for GPUdb userID
                                                        Default: ${GPUDB_PASSWORD}
              --tuser                             : To provide value for TESTMGR_USER
                                                        Default: ${TESTMGR_USER}
              --tpwd                              : To provide value for TESTMGR_PASSWORD
                                                        Default: ${TESTMGR_PASSWORD}
              --project-dir                       : Provide project directory of the remote machine
                                                        Default: ${PROJECT_DIR}
              --sequential                        : Run only on one server.
              --parallel                          : Run on multiple servers in parallel.
              --build-name                        : Build Name of the instance.

      Examples:
        1. Help message
            ${SCRIPT_DIR}/${THIS} --help

        2. Execute tests and sends results to QE TestMgr
           ${SCRIPT_DIR}/${THIS} --sequential --gpudb '${HOST}' --user '${GPUDB_USER}' --password '${GPUDB_PASSWORD}' --tuser '${TESTMGR_USER}' --tpwd '${TESTMGR_PASSWORD}' --project-dir '${PROJECT_DIR}' --build-name '${BUILD_NAME}'

        3. Execute tests in parallel and sends results to QE TestMgr
           ${SCRIPT_DIR}/${THIS} --parallel --gpudb '${HOST},172.31.33.33' --user '${GPUDB_USER}' --password '${GPUDB_PASSWORD}' --tuser '${TESTMGR_USER}' --tpwd '${TESTMGR_PASSWORD}' --project-dir '${PROJECT_DIR}' --build-name '${BUILD_NAME}'

    """
    echo "${HELP_STR}"
}

function parse_command_line_arguments(){
    while [[ $# -gt 0 ]]; do
        key="$1"
        shift

        case $key in
            --gpudb)
                HOST="$1"
                shift
                ;;

            --user)
                GPUDB_USER="$1"
                shift
                ;;

            --password)
                GPUDB_PASSWORD="$1"
                shift
                ;;

            --tuser)
                TESTMGR_USER="$1"
                shift
                ;;

            --tpwd)
                TESTMGR_PASSWORD="$1"
                shift
                ;;

            --remote-gpudb-home)
                REMOTE_GPUDB_HOME="$1"
                shift
                ;;

            --project-dir)
                PROJECT_DIR="$1"
                shift
                ;;

            --sequential)
                SEQUENTIAL=1
                ;;

            --parallel)
                PARALLEL=1
                ;;

            --build-name)
                BUILD_NAME="$1"
                shift
                ;;

            -h|--help)
                options_menu
                exit 1
                ;;

            *)
                echo "ERROR: Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done
}

function executor() {
  local SEQUENTIAL_JOB_FOUND
  local PARALLEL_JOB_FOUND
  SEQUENTIAL_JOB_FOUND=$(${JENKINS_CMD_PREFIX} list-jobs | grep "${SEQUENTIAL_PROJECT_NAME}")
  PARALLEL_JOB_FOUND=$(${JENKINS_CMD_PREFIX} list-jobs | grep "${PARALLEL_PROJECT_NAME}")

  if [[ -z ${SEQUENTIAL_JOB_FOUND} ]]; then
      ${JENKINS_CMD_PREFIX} create-job "${SEQUENTIAL_PROJECT_NAME}" < "${SEQUENTIAL_JENKINS_JOB_CONFIG}"
  fi

  if [[ -z ${PARALLEL_JOB_FOUND} ]]; then
      ${JENKINS_CMD_PREFIX} create-job "${PARALLEL_PROJECT_NAME}" < "${PARALLEL_JENKINS_JOB_CONFIG}"
  fi

  [[ ${SEQUENTIAL} -eq 1 ]] && ${JENKINS_CMD_PREFIX} build "${SEQUENTIAL_PROJECT_NAME}" -s -v -p hostIp="${HOST}" -p remoteGpudbHome="${REMOTE_GPUDB_HOME}" -p projectDir="${PROJECT_DIR}" -p user="${GPUDB_USER}" -p password="${GPUDB_PASSWORD}" -p tuser="${TESTMGR_USER}" -p tpwd="${TESTMGR_PASSWORD}" -p buildName="${BUILD_NAME}"
  [[ ${PARALLEL} -eq 1 ]] && ${JENKINS_CMD_PREFIX} build "${PARALLEL_PROJECT_NAME}" -s -v -p ServerIpList="${HOST}" -p JenkinsJob="${SEQUENTIAL_PROJECT_NAME}" -p remoteGpudbHome="${REMOTE_GPUDB_HOME}" -p projectDir="${PROJECT_DIR}" -p user="${GPUDB_USER}" -p password="${GPUDB_PASSWORD}" -p tuser="${TESTMGR_USER}" -p tpwd="${TESTMGR_PASSWORD}" -p buildName="${BUILD_NAME}"
}

parse_command_line_arguments "$@"
executor

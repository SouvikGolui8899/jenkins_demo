def remote = [:]
remote.name = "Kinetica@${params.hostIp}"
remote.host = "${params.hostIp}"
remote.user = 'gpudb'
remote.password = 'gisfed11'
remote.allowAnyHosts = true

pipeline {
    agent any

    stages {
        stage('Test load-export-import-test(Cypress Test)') {
            when {
                expression {
                    params.projectDir != params.remoteGpudbHome
                }
            }

            steps {
                script {
                   currentBuild.displayName = "${params.buildName}"
                }
                sshCommand remote: remote, command: "rm -rf ${params.projectDir}"
                sshCommand remote: remote, command: "mkdir -p ${params.projectDir}"
                sshCommand remote: remote, command: "pushd ${params.projectDir}; git clone git@bitbucket.org:gisfederal/gpudb-qa.git; popd"
                sshCommand remote: remote, command: "pushd ${params.projectDir}/gpudb-qa/gui_tests/cypress-tests/load-export-import-test; ./bin/test-regression.sh --rat --user ${params.user} --password ${params.password} --tuser ${params.tuser} --tpwd ${params.tpwd}; popd"
            }
        }

        stage('Publish test results') {
            steps {
                sh 'mkdir -p test_results/'
                sshGet remote: remote, from: "${params.projectDir}/gpudb-qa/gui_tests/cypress-tests/load-export-import-test/logs", into: "test_results", override: true
                junit "test_results/logs/*.xml"
            }
        }
    }
}
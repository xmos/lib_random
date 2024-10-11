@Library('xmos_jenkins_shared_library@v0.34.0') _

getApproval()

pipeline {
  agent {
    label 'x86_64 && linux'
  }
  environment {
    REPO = 'lib_random'
  }
  options {
    buildDiscarder(xmosDiscardBuildSettings())
    skipDefaultCheckout()
    timestamps()
  }
  parameters {
    string(
      name: 'TOOLS_VERSION',
      defaultValue: '15.3.0',
      description: 'The XTC tools version'
    )
    string(
      name: 'XMOSDOC_VERSION',
      defaultValue: 'v6.1.2',
      description: 'The xmosdoc version'
    )
  }

  stages {
    stage('Build') {
      steps {
        dir("lib_random") {
          checkout scm

          withTools(params.TOOLS_VERSION) {
            dir("examples") {
              sh 'cmake -G "Unix Makefiles" -B build'
              sh 'xmake -C build'
            }
          }
        }
      }
    } // Build

    stage('Library checks') {
      steps {
        runLibraryChecks("${WORKSPACE}/${REPO}", "v2.0.1")
      }
    }

    stage('Documentation') {
      steps {
        dir("${REPO}") {
          buildDocs()
        }
      }
    }

  } // stages
  post {
     cleanup {
          xcoreCleanSandbox()
    }
  }
}

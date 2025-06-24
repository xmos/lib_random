@Library('xmos_jenkins_shared_library@v0.39.0') _

getApproval()

pipeline {
  agent {
    label 'x86_64 && linux'
  }
  environment {
    REPO = 'lib_random'
    REPO_NAME = 'lib_random'
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
      defaultValue: 'v7.1.0',
      description: 'The xmosdoc version'
    )
    string(
      name: 'INFR_APPS_VERSION',
      defaultValue: 'v2.1.0',
      description: 'The infr_apps version'
    )
  }

  stages {
    stage('Build') {
      steps {
        dir("${REPO}") {
          checkoutScmShallow()

          withTools(params.TOOLS_VERSION) {
            dir("examples") {
              xcoreBuild()
            }
          }
        }
      }
    } // Build

    stage('Library checks') {
      steps {
        runLibraryChecks("${WORKSPACE}/${REPO}", "${params.INFR_APPS_VERSION}")
      }
    }

    stage('Documentation') {
      steps {
        dir("${REPO}") {
          buildDocs()
        }
      }
    }

    stage("Archive sandbox"){
      steps {
        archiveSandbox(REPO)
      }
    }

  } // stages
  post {
     cleanup {
          xcoreCleanSandbox()
    }
  }
}

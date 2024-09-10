@Library('xmos_jenkins_shared_library@v0.33.0') _

getApproval()

pipeline {
  agent {
    label 'x86_64 && linux'
  }
  environment {
    XTC_VERSION = '15.3.0'
  }
  options {
    buildDiscarder(xmosDiscardBuildSettings())
    skipDefaultCheckout()
    timestamps()
  }
  stages {
    stage('Build') {
      steps {
        dir("lib_random") {
          checkout scm

          withTools(env.XTC_VERSION) {
            dir("examples") {
              sh 'cmake -G "Unix Makefiles" -B build'
              sh 'xmake -C build'
            }
          }
        }
      }
      post {
        cleanup {
          xcoreCleanSandbox()
        }
      }
    }
  }
}

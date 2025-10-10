@Library('xmos_jenkins_shared_library@v0.43.0') _

getApproval()

pipeline {
  agent none
  
  options {
    buildDiscarder(xmosDiscardBuildSettings())
    skipDefaultCheckout()
    timestamps()
  }

  parameters {
    string(
      name: 'TOOLS_VERSION',
      defaultValue: '15.3.1',
      description: 'The XTC tools version'
    )
    string(
      name: 'XMOSDOC_VERSION',
      defaultValue: 'v8.0.0',
      description: 'The xmosdoc version'
    )
    string(
      name: 'INFR_APPS_VERSION',
      defaultValue: 'v3.1.1',
      description: 'The infr_apps version'
    )
  }

  stages {
    stage('🏗️ Build and test') {
      agent {
        label 'x86_64 && linux && documentation'
      }

      stages {
        stage('Build') {
          steps {

            println "Stage running on ${env.NODE_NAME}"

            script {
              def (server, user, repo) = extractFromScmUrl()
              env.REPO_NAME = repo
            }

            dir(REPO_NAME) {
              checkoutScmShallow()

              withTools(params.TOOLS_VERSION) {
                dir("examples") {
                  xcoreBuild()
                }
                dir("tests") {
                  xcoreBuild()
                }
              }
            }
          }
        } // Build

        stage('Library checks') {
          steps {
            warnError("Repo checks failed") {
              runRepoChecks("${WORKSPACE}/${REPO_NAME}")
            }
          }
        }

        stage('Documentation') {
          steps {
            dir(REPO_NAME) {
              buildDocs()
            }
          }
        }

        stage("Archive sandbox") {
          steps {
            archiveSandbox(REPO_NAME)
          }
        }

      } // stages
      post {
        cleanup {
          xcoreCleanSandbox()
        }
      }
    } // stage 'Build and test'
    
    stage('🚀 Release') {
      when {
        expression { triggerRelease.isReleasable() }
      }
      steps {
        triggerRelease()
      }
    }
  }
}

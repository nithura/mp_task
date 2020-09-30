// change the values xxx
// install ansiColor plugin

pipeline{
    agent any
    stages{
         stage('download_modules'){
             steps {
                dir ('modules') {
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/xxx']],
                        doGenerateSubmoduleConfigurations: false,
                        extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'xxxxxxx']],
                        submoduleCfg: [],
                        userRemoteConfigs: [[
                            credentialsId: '',
                            url: 'xxxx'
                        ]]
                    ])
                }
            }
        }
        stage('terragrunt_plan'){
            steps {
                dir ('modules/XXXX') {
                    ansiColor('xterm') {
                        sh "terragrunt init"
                        sh "terragrunt plan -target=module.cluster-autoscaler.helm_release.this[0] -out myplan"
                    }
                }
                
            }
        }
        stage('terragrunt_Approval'){
            steps {
                script {
                    def userInput = input(id: 'confirm', message: 'Apply terragrunt?', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Apply terragrunt', name: 'confirm'] ])
                }
                
            }
        }
        stage('terragrunt_apply'){
            steps{
                dir ('modules/XXX'){
                ansiColor('xterm'){
                    sh "terragrunt apply -input=false myplan"
                }
            }
          }
        }
    }
}
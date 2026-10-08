pipeline {
    agent any

    parameters {
        choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Terraform action to perform')
        booleanParam(name: 'AUTO_APPROVE', defaultValue: true, description: 'Automatically approve without manual input')
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION    = 'us-east-1'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init -input=false'
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -input=false -out=tfplan'
            }
        }

        stage('Approval') {
            when {
                allOf {
                    expression { params.ACTION != 'plan' }
                    expression { params.AUTO_APPROVE == false }
                }
            }
            steps {
                input message: "Review the plan above. Proceed with terraform ${params.ACTION}?",
                      ok: "Yes, run ${params.ACTION}"
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    // Check the saved plan for a newly created (or replaced) bastion SSH key
                    def newKey = sh(
                        script: "terraform show -no-color tfplan | grep -qE 'tls_private_key\\.bastion (will be created|must be replaced)'",
                        returnStatus: true
                    ) == 0

                    sh 'terraform apply -input=false tfplan'

                    if (newKey) {
                        echo 'New bastion SSH key was created - archiving bastion-key.pem for download.'
                        sh '''
                            set +x
                            umask 077
                            terraform output -raw bastion_ssh_private_key > bastion-key.pem
                        '''
                        archiveArtifacts artifacts: 'bastion-key.pem', fingerprint: true
                    } else {
                        echo 'Bastion SSH key unchanged - no new .pem to download.'
                    }
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                sh 'terraform destroy -input=false -auto-approve'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo "Terraform ${params.ACTION} completed successfully!"
        }
        failure {
            echo "Terraform ${params.ACTION} failed. Check the logs."
        }
    }
}

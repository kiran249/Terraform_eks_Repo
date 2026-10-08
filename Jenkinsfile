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
        TF_IN_AUTOMATION      = 'true'
        TF_INPUT              = 'false'
    }

    options {
        // Never run two Terraform jobs against the same state at once
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                bat 'terraform init -input=false -reconfigure'
            }
        }

        stage('Terraform Validate') {
            steps {
                bat 'terraform fmt -check -recursive'
                bat 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            steps {
                script {
                    // For destroy, generate a destroy plan so the approval step reviews what will be deleted
                    def destroyFlag = params.ACTION == 'destroy' ? '-destroy ' : ''
                    bat "terraform plan -input=false -lock-timeout=5m ${destroyFlag}-out=tfplan"
                }
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
                bat 'terraform apply -input=false -lock-timeout=5m tfplan'
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                // Applying a saved destroy plan performs exactly the reviewed deletion
                bat 'terraform apply -input=false -lock-timeout=5m tfplan'
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

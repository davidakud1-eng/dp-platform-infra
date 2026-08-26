pipeline {
    agent { label 'platform-ops' }

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    parameters {
        booleanParam(
            name: 'EKS_RUNTIME_ENABLED',
            defaultValue: false,
            description: 'Include the ephemeral DP EKS runtime in the Terraform plan.'
        )
    }

    environment {
        // ================================================================
        // Terraform Configuration
        // ================================================================

        TF_IN_AUTOMATION = 'true'
        TF_INPUT = 'false'
    }

    stages {

        // ==================================================================
        // Checkout
        // ==================================================================

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        // ==================================================================
        // Verify Terraform
        // ==================================================================

        stage('Verify Terraform') {
            steps {
                sh '''
                    terraform version
                    aws --version
                '''
            }
        }

        // ==================================================================
        // Terraform Format Check
        // ==================================================================

        stage('Terraform Format Check') {
            steps {
                sh '''
                    terraform fmt -check -recursive
                '''
            }
        }

        // ==================================================================
        // Terraform Init
        // ==================================================================

        stage('Terraform Init') {
            steps {
                sh '''
                    terraform init -input=false
                '''
            }
        }

        // ==================================================================
        // Terraform Validate
        // ==================================================================

        stage('Terraform Validate') {
            steps {
                sh '''
                    terraform validate
                '''
            }
        }

        // ==================================================================
        // Terraform Plan
        //
        // EKS remains disabled by default.
        // Enabling the Jenkins parameter causes Terraform to include the
        // ephemeral EKS runtime and its dependent infrastructure.
        // ==================================================================

        stage('Terraform Plan') {
            steps {
                sh '''
                    terraform plan \
                        -input=false \
                        -var="enable_eks_runtime=${EKS_RUNTIME_ENABLED}" \
                        -out=dp.tfplan
                '''
            }
        }

        // ==================================================================
        // Display Plan
        // ==================================================================

        stage('Display Terraform Plan') {
            steps {
                sh '''
                    terraform show -no-color dp.tfplan
                '''
            }
        }
    }

    post {

        success {
            echo 'DP infrastructure validation and Terraform plan completed successfully.'
        }

        failure {
            echo 'DP infrastructure pipeline failed.'
        }

        always {
            sh '''
                rm -f dp.tfplan
            '''
        }
    }
}
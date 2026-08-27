pipeline {
    agent { label 'platform-ops' }

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    parameters {

        // ================================================================
        // EKS Runtime Control
        //
        // Controls whether the ephemeral DP EKS runtime is included
        // in the desired Terraform state.
        // ================================================================

        booleanParam(
            name: 'EKS_RUNTIME_ENABLED',
            defaultValue: true,
            description: 'Include the ephemeral DP EKS runtime in the Terraform configuration.'
        )

        // ================================================================
        // Terraform Apply Control
        //
        // Disabled by default so normal repository changes perform
        // validation and planning without modifying AWS infrastructure.
        // ================================================================

        booleanParam(
            name: 'TERRAFORM_APPLY',
            defaultValue: false,
            description: 'Apply the generated Terraform plan to AWS.'
        )
    }

    environment {

        // ================================================================
        // Terraform Configuration
        // ================================================================

        TF_IN_AUTOMATION = 'true'
        TF_INPUT = 'false'

        // ================================================================
        // Jenkins Parameter Mapping
        //
        // Jenkins build parameters are explicitly mapped to environment
        // variables for shell commands executed by the pipeline.
        // ================================================================

        DP_EKS_RUNTIME_ENABLED = "${params.EKS_RUNTIME_ENABLED}"
        DP_TERRAFORM_APPLY = "${params.TERRAFORM_APPLY}"
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
        // Verify Terraform, AWS CLI, and AWS Execution Identity
        //
        // The AWS identity should resolve to the IAM role attached to the
        // DP Platform Operations EC2 instance.
        // ==================================================================

        stage('Verify Tooling') {
            steps {
                sh '''
                    echo "=== TERRAFORM ==="
                    terraform version

                    echo
                    echo "=== AWS CLI ==="
                    aws --version

                    echo
                    echo "=== AWS EXECUTION IDENTITY ==="
                    aws sts get-caller-identity
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
        // EKS_RUNTIME_ENABLED controls whether Terraform includes the
        // ephemeral EKS runtime and its dependent infrastructure.
        //
        // The Jenkins parameter is mapped to DP_EKS_RUNTIME_ENABLED so
        // Terraform receives an explicit boolean value.
        //
        // The resulting plan is saved so that, when TERRAFORM_APPLY=true,
        // Jenkins applies exactly the plan produced by this stage.
        // ==================================================================

        stage('Terraform Plan') {
            steps {
                sh '''
                    echo "=== DP TERRAFORM RUNTIME CONFIGURATION ==="
                    echo "EKS_RUNTIME_ENABLED=${DP_EKS_RUNTIME_ENABLED}"
                    echo "TERRAFORM_APPLY=${DP_TERRAFORM_APPLY}"

                    terraform plan \
                        -input=false \
                        -var="enable_eks_runtime=${DP_EKS_RUNTIME_ENABLED}" \
                        -out=dp.tfplan
                '''
            }
        }

        // ==================================================================
        // Display Terraform Plan
        // ==================================================================

        stage('Display Terraform Plan') {
            steps {
                sh '''
                    terraform show -no-color dp.tfplan
                '''
            }
        }

        // ==================================================================
        // Terraform Apply
        //
        // Infrastructure changes are deliberately disabled by default.
        //
        // When TERRAFORM_APPLY=true, Jenkins applies exactly the saved
        // Terraform plan generated by the preceding Plan stage.
        //
        // AWS authentication is provided by the IAM role attached to the
        // DP Platform Operations EC2 instance. No long-lived AWS access
        // keys are stored in Jenkins for this operation.
        // ==================================================================

        stage('Terraform Apply') {

            when {
                expression {
                    return params.TERRAFORM_APPLY
                }
            }

            steps {
                sh '''
                    echo "=== APPLYING DP TERRAFORM PLAN ==="

                    terraform apply \
                        -input=false \
                        -auto-approve \
                        dp.tfplan
                '''
            }
        }

        // ==================================================================
        // Verify EKS Runtime
        //
        // Runs only when:
        //   1. EKS is part of the desired runtime, and
        //   2. Terraform was actually applied.
        //
        // This verifies AWS-side creation of the EKS cluster and confirms
        // that Platform Ops can authenticate to and communicate with it.
        // ==================================================================

        stage('Verify EKS Runtime') {

            when {
                allOf {
                    expression {
                        return params.EKS_RUNTIME_ENABLED
                    }

                    expression {
                        return params.TERRAFORM_APPLY
                    }
                }
            }

            steps {
                sh '''
                    echo "=== VERIFY EKS CLUSTER ==="

                    aws eks describe-cluster \
                        --region us-east-2 \
                        --name dp-eks-cluster \
                        --query 'cluster.{Name:name,Status:status,Version:version,Endpoint:endpoint}' \
                        --output table

                    echo
                    echo "=== CONFIGURE KUBECONFIG ==="

                    aws eks update-kubeconfig \
                        --region us-east-2 \
                        --name dp-eks-cluster

                    echo
                    echo "=== VERIFY EKS NODES ==="

                    kubectl get nodes -o wide
                '''
            }
        }
    }

    post {

        // ==================================================================
        // Pipeline Result
        // ==================================================================

        success {
            echo 'DP infrastructure pipeline completed successfully.'
        }

        failure {
            echo 'DP infrastructure pipeline failed.'
        }

        // ==================================================================
        // Cleanup
        //
        // Remove the saved Terraform plan after the pipeline completes.
        // ==================================================================

        always {
            sh '''
                rm -f dp.tfplan
            '''
        }
    }
}
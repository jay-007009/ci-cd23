resource "aws_codebuild_project" "tf-plan" {
  name        = "tf-cicd-plan"
  description = "Plan Storage for terraform "

  service_role = aws_iam_role.tf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }



  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0" //"hashicorp/terraform"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD" //SERVICE_ROLE CODEBUILD

     # registry_credential { //docker nu che 
    #     credentials=var.dockerhub_credentials
    #     credential_provider="SECRETS_MANAGER"
    # }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec/plan-buildspec.yml")
  }
}


resource "aws_codebuild_project" "tf-apply" {
  name        = "tf-cicd-apply"
  description = "Apply Stage for terraform "

  service_role = aws_iam_role.tf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }



  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD" //SERVICE_ROLE CODEBUILD

      # registry_credential { //docker nu che 
    #     credentials=var.dockerhub_credentials
    #     credential_provider="SECRETS_MANAGER"
    # }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec/apply-buildspec.yml")
  }
}


resource "aws_codepipeline" "cicd_pipeline" {
  name     = "tf-cicd"
  role_arn = aws_iam_role.tf-codepipeline-role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.id
    type     = "S3"


  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["tf-code"]

      configuration = {
        ConnectionArn        = var.codestar_connector_credentials
        FullRepositoryId     = "ci-cd23"
        BranchName           = "master"
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Plan"

    action {
      name            = "Build"
      owner           = "AWS"
      category        = "Build"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["tf-code"]
      configuration = {
        ProjectName = "tf-cicd-plan"
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      owner           = "AWS"
      category        = "Build"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["tf-code"]
      configuration = {
        ProjectName = "tf-cicd-plan"
      }
    }
  }
}
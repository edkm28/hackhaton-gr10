terraform {
  required_version = ">= 1.1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-3" # Region  
  access_key = "AKIA6KJF5CGEEQVILBWL"
  secret_key = "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"    
}

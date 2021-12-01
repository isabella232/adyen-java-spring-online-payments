terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "eu-west-1"
}

data "archive_file" "api_dist_zip" {
  type        = "zip"
  source_file = "${path.root}/${var.api_dist}.jar"
  output_path = "${path.root}/${var.api_dist}.zip"
}

resource "aws_s3_bucket" "dist_bucket" {
  bucket = "${var.namespace}-elb-dist"
  acl    = "private"
}
resource "aws_s3_bucket_object" "dist_item" {
  key    = "${var.environment}/dist-${uuid()}"
  bucket = "${aws_s3_bucket.dist_bucket.id}"
  source = "${path.root}/${var.api_dist}.zip"
}

resource "aws_elastic_beanstalk_application" "tftest" {
  name        = "tf-test-name"
  description = "tf-test-desc"
}

resource "aws_elastic_beanstalk_application_version" "beanstalk_myapp_version" {
  application = aws_elastic_beanstalk_application.tftest.name
  bucket = aws_s3_bucket.dist_bucket.id
  key = aws_s3_bucket_object.dist_item.id
  name = "${var.namespace}-1.0.0"
}

resource "aws_elastic_beanstalk_environment" "tfenvtest" {
  name                = "tf-test-name"
  application         = aws_elastic_beanstalk_application.tftest.name
  solution_stack_name = "64bit Amazon Linux 2 v3.2.8 running Corretto 11"
  version_label = aws_elastic_beanstalk_application_version.beanstalk_myapp_version.name

  setting {
    namespace = "aws:ec2:instances"
    name = "InstanceTypes"
    value = "t2.micro"
  }
  setting {
   namespace = "aws:autoscaling:launchconfiguration"
   name = "IamInstanceProfile"
   value = "aws-elasticbeanstalk-ec2-role"
  }

  setting {
    name = "PORT"
    namespace = "aws:elasticbeanstalk:application:environment"
    value = "8080"
  }

  setting {
    name = "ADYEN_CLIENT_KEY"
    namespace = "aws:elasticbeanstalk:application:environment"
    value = "testKey"
  }

  setting {
    name = "ADYEN_API_KEY"
    namespace = "aws:elasticbeanstalk:application:environment"
    value = "testKey"
  }

  setting {
    name = "ADYEN_HMAC_KEY"
    namespace = "aws:elasticbeanstalk:application:environment"
    value = "testKey"
  }

  setting {
    name = "ADYEN_MERCHANT_ACCOUNT"
    namespace = "aws:elasticbeanstalk:application:environment"
    value = "testKey"
  }

  setting {
    name = "ADYEN_RETURN_URL"
    namespace = "aws:elasticbeanstalk:application:environment"
    value = "testKey"
  }
}
terraform {
  backend "s3" {
    bucket = "buckettech5douglas"
    key    = "terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "terraform-locks-tech5-douglas"
    encrypt        = true
  }
}

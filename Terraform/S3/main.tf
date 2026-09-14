resource "aws_s3_bucket" "example" {
  bucket = "s3-velero-bucket-tech05-backup"

  tags = {
    Name        = "SolidaryTech"
    Environment = "Production"
    CostCenter  = "Velero-bucket"
  }
}
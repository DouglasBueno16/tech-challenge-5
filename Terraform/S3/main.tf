resource "aws_s3_bucket" "bucket" {
  bucket = "s3-velero-bucket-tech05-backup"

  tags = {
    Name        = "SolidaryTech"
    Environment = "Production"
    CostCenter  = "Velero-bucket"
  }
}
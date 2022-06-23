# --- root/backend.tf ---

terraform {
  backend "s3" {
    bucket = "hackhaton-saagie-estiam-groupe10-89747162"
    key    = "remote.tfstate"
    region = "eu-west-3"
  }
}
# --- root/backend.tf ---

terraform {
  backend "s3" {
    bucket = "hackhaton-saagie-estiam-groupe10-89747162"
    region = "EU (Paris) eu-west-3"
  }
}
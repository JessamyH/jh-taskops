terraform {
  backend "s3" {
    bucket       = "jessamy-lab-tfstate-956519721376"
    key          = "jh-taskops/prod/terraform.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    use_lockfile = true
  }
}

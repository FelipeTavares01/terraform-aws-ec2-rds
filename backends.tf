terraform {
  backend "remote" {
    organization = "ltc-terraform"

    workspaces {
      name = "terraform-aws"
    }
  }
}
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  profile = "default"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_instance" "app_server" {
  ami = "ami-06ee4e2261a4dc5c3"
  instance_type = "t2.micro"
  tags = {
    "Name" = "skill-check"
  }
}

resource "aws_key_pair" "skill-check-key" {
  key_name   = "skill-check"
  public_key = file("~/.ssh/id_aws_ed25519.pub") 
}

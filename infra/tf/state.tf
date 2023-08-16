terraform {
  backend "gcs" {
    bucket = "gc-mc-demo-prime-tsfvjgk"
    prefix = "tfstate"
  }
}


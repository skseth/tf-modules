terraform {
  required_providers {
    atlas = {
      source  = "ariga/atlas"
      version = "~> 0.10.1"
    }

    mysql = {
      source  = "petoju/mysql"
      version = ">=3.0.93"
    }  
  }

}
provider "atlas" {
  # Use MySQL 8 docker image as the dev database.
}


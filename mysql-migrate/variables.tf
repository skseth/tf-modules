variable "uri" {
    type = string
    default = ""
}

variable "schemas" {
    type = map(object({
        name = string,
        hcl = string,
        md5 = string
    }))
    default = {
    }
}


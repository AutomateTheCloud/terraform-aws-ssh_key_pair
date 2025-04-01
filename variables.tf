variable "name" {
  description = "SSH Key Pair Name"
  type        = string
  default     = ""
  validation {
    condition     = var.name != ""
    error_message = "SSH Key Pair Name not Specified."
  }
}

variable "public_key" {
  description = "SSH Public Key"
  type        = string
  default     = ""
  validation {
    condition     = var.public_key != ""
    error_message = "SSH Public Key not Specified."
  }
}

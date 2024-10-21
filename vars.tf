variable "projeto" {
  description = "Nome do projeto"
  type        = string
  default     = "VExpenses"
}

variable "candidato" {
  description = "Nome do candidato"
  type        = string
  default     = "LuisFelipe"
}

variable "regiao" {
  default = "us-east-1"
}

variable "zona" {
  default = "us-east-1a"
}

variable "meuIp" {
  default = "192.168.1.100/32" 
}
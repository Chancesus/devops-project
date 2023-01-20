variable "name" {
    default = "Admin"
    description = "Name the instance on deploy"
}

variable "group" {
    description = "the group tag for ansible to identify"
}

variable "profile" {
    description = "profile we will use for deploy"
}
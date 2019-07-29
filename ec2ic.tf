provider "aws" {
    profile = "default"
    region = "us-east-1"
}

variable "user_source_cidr" {
    type = "list"
    description = "The egress IP address/range for connecting to EC2 instances over SSH."
}

variable "user_region" {
    type = "string"
}

variable "user_account" {
    type = "string"
}

resource "aws_vpc" "main-vpc" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_hostnames = true
}


resource "aws_subnet" "public-1" {
    vpc_id="${aws_vpc.main-vpc.id}"
    cidr_block="10.0.1.0/24"
    map_public_ip_on_launch = "true"
    tags = {
        Name = "public"
    }
}

resource "aws_subnet" "private-1" {
    vpc_id = "${aws_vpc.main-vpc.id}"
    cidr_block = "10.0.100.0/24"
    map_public_ip_on_launch = "false"
    tags = { 
        Name = "private"
    }
}

resource "aws_internet_gateway" "main-igw" {
    vpc_id = "${aws_vpc.main-vpc.id}"
    tags = {
        Name = "igw"
    }
}

resource "aws_route_table" "public-route-table" {
    vpc_id = "${aws_vpc.main-vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.main-igw.id}"
    }
    tags = {
        Name = "Public Subnet Route Table"
    }
}

resource "aws_route_table_association" "public-association" {
    subnet_id = "${aws_subnet.public-1.id}"
    route_table_id = "${aws_route_table.public-route-table.id}"
}

resource "aws_instance" "ec2_instance_connect" {
    ami = "ami-0b898040803850657"
    instance_type ="t2.micro"
    subnet_id="${aws_subnet.public-1.id}"
    vpc_security_group_ids=["${aws_security_group.ssh_ec2ic.id}"]
    user_data = "yum install ec2-instance-connect"
}

resource "aws_security_group" "ssh_ec2ic" {
    name = "ssh_ec2_instance_connect"
    description = "security group for ec2 instance connect"
    vpc_id = "${aws_vpc.main-vpc.id}"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = var.user_source_cidr
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

# "Resource": "arn:aws:ec2:<<REGION>>:<<ACCOUNTNUMBERNOHYPHEN>>:instance/${aws_instance.ec2_instance_connect.id}",

resource "aws_iam_policy" "ec2_ic_policy" {
    name = "ec2_ic_policy"
    path = "/"
    description = "Policy to grant IAM users the ability to SSH using EC2 instance connect."

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ec2-instance-connect:SendSSHPublicKey",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "ec2:osuser": "ec2-user"
                }
            }
        }]
    }
    EOF
}


output "ec2_instance_id" {
    value = "${aws_instance.ec2_instance_connect.id}"
}

output "ec2_server_ip" {
    value = "${aws_instance.ec2_instance_connect.public_ip}"
}

output "vpc-publicsubnet-id" {
    value = "${aws_subnet.public-1.id}"
}

output "vpc-publicsubnet-cidr" {
    value = "${aws_subnet.public-1.cidr_block}"
}

output "vpc-privatesubnet-id" {
    value = "${aws_subnet.private-1.id}"
}

output "vpc-privatesubnet-cidr" {
    value = "${aws_subnet.private-1.cidr_block}"
}

output "vpc-id" {
    value = "${aws_vpc.main-vpc.id}"
}

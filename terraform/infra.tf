
# Add your VPC ID to default below
variable "vpc_id" {
  description = "VPC ID for usage throughout the build process"
  default = "vpc-29e0114e"
}

# Configure the AWS Provider
provider "aws" {
  region     = "us-west-2"
}

#Creates an internet gateway 
resource "aws_internet_gateway" "gw" {
  vpc_id = "${var.vpc_id}"

  tags = {
    Name = "Internet gateway"
  }
}

#Creates a public routing table 
resource "aws_route_table" "public_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {

    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "public_routing_table"
  }
}

#Creates a public subnet 
#to create more subnets replicate code 2 more times all with different cidr "/24"
resource "aws_subnet" "public_subnet_1" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.0.0/24"
    availability_zone = "us-west-2a"

    tags {
        Name = "public_1"
    }
}

#2nd public subnet
resource "aws_subnet" "public_subnet_2" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.1.0/24"
    availability_zone = "us-west-2b"

    tags {
        Name = "public_2"
    }
}

#3rd public subnet
resource "aws_subnet" "public_subnet_3" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.2.0/24"
    availability_zone = "us-west-2c"

    tags {
        Name = "public_3"
    }
}



#associates a subnet with the routing table 
#route table assoc for pub_subnet_1
resource "aws_route_table_association" "public_subnet_1_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_1.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}

#route table assoc for pub_subnet_2
resource "aws_route_table_association" "public_subnet_2_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_2.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}

#route table assoc for pub_subnet_3
resource "aws_route_table_association" "public_subnet_3_rt_assoc" {
    subnet_id = "${aws_subnet.public_subnet_3.id}"
    route_table_id = "${aws_route_table.public_routing_table.id}"
}

#create a security group 
resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "Allow ssh inbound traffic"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["172.31.0.0/24"]
  }
}

# Create a new instance of the latest linux 
resource "aws_instance" "bastion" {
    ami = "ami-b04e92d0" 
    associate_public_ip_address = true
    subnet_id = "${aws_subnet.public_subnet_1.id}"
    instance_type = "t2.micro"
    tags {
        Name = "Bastion instance "
    }
}

#Start of Private subnet and Nat gateway
#Builds a nat gateway 
resource "aws_nat_gateway" "nat_gw" {
    allocation_id = "${aws_eip.nat.id}"
    subnet_id = "${aws_subnet.private_subnet_1.id}"
   # subnet_id = "${aws_subnet.private_subnet_2.id}"
}

#create EIP
resource "aws_eip" "nat" {
  vpc      = true
}



#Creates a private gate 1 routing table 
resource "aws_route_table" "pri_routing_table" {
  vpc_id = "${var.vpc_id}"
  route {

    cidr_block = "0.0.0.0/0"
    #gateway_id = "${aws_internet_gateway.gw.id}"
    nat_gateway_id = "${aws_nat_gateway.nat_gw.id}"
  }

  tags {
    Name = "private_routing_table"
  }
}



#Creates a private subnet 
#to create more subnets replicate code 2 more times all with different cidr "/22"
resource "aws_subnet" "private_subnet_1" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.5.0/22"
    availability_zone = "us-west-2a"

    tags {
        Name = "private_1"
    }
}


#Creates 2nd private subnet
#to create more subnets replicate code 2 more times all with different cidr "/22"
resource "aws_subnet" "private_subnet_2" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.9.0/22"
    availability_zone = "us-west-2b"

    tags {
        Name = "private_2"
    }
}

#Creates 3rd private subnet
#to create more subnets replicate code 2 more times all with different cidr "/22"
resource "aws_subnet" "private_subnet_3" {
    vpc_id = "${var.vpc_id}"
    cidr_block = "172.31.13.0/22"
    availability_zone = "us-west-2c"

    tags {
        Name = "private_3"
    }
}


#associates a subnet with the routing table 
#route table assoc for private_subnet_1
resource "aws_route_table_association" "private_subnet_1_rt_assoc" {
    subnet_id = "${aws_subnet.private_subnet_1.id}"
    route_table_id = "${aws_route_table.pri_routing_table.id}"
}

#associates a subnet with the routing table 
#route table assoc for private_subnet_2
resource "aws_route_table_association" "private_subnet_2_rt_assoc" {
    subnet_id = "${aws_subnet.private_subnet_2.id}"
    route_table_id = "${aws_route_table.pri_routing_table.id}"
}

#associates a subnet with the routing table 
#route table assoc for private_subnet_3
resource "aws_route_table_association" "private_subnet_3_rt_assoc" {
    subnet_id = "${aws_subnet.private_subnet_3.id}"
    route_table_id = "${aws_route_table.pri_routing_table.id}"
}

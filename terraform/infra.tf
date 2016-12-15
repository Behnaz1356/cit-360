# Add your VPC ID to default below
variable "vpc_id" {
  description = "VPC ID for usage throughout the build process"
  default = "vpc-29e0114e"
}

variable "aws_key_name" {
  default = "cit360"
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
    cidr_block = "172.31.3.0/24"
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
#start of attempt at nat

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



#create a security group 
resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "Allow ssh inbound traffic"

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  } 
}

# Create a new instance of the latest linux on an
# t2.micro node 
resource "aws_instance" "bastion" {
    ami = "ami-5ec1673e" 
    associate_public_ip_address = true
    subnet_id = "${aws_subnet.public_subnet_1.id}"
    instance_type = "t2.micro"
    
    key_name = "${var.aws_key_name}"
    vpc_security_group_ids = ["${aws_security_group.allow_ssh.id}"]
    tags {
        Name = "Bastion instance "
    }
}

#Create a DB subnet
resource "aws_db_subnet_group" "DB_subnet_group" {
    name = "db subnet"
    subnet_ids = ["${aws_subnet.private_subnet_1.id}", "${aws_subnet.private_subnet_2.id}"]
    tags {
        Name = " DB subnet group"
    }
}


 #Create maria db
resource "aws_db_instance" "mariaDB" {
  allocated_storage    = 5
  engine               = "mariadb"
  engine_version       = "10.0.24"
  instance_class       = "db.t2.micro"
  name                 = "mariadatabase"
 username             = "root"
  password             = "${var.mariadb_password}"
  multi_az             = "false"
  storage_type         = "gp2"
  db_subnet_group_name = "${aws_db_subnet_group.DB_subnet_group.id}"
  vpc_security_group_ids = ["${aws_security_group.sec_grp_2.id}"]
  tags {
        #Name = "Maria Database "
    }
}

#a security group with port 80, port 22
resource "aws_security_group" "sec_grp_2" {
  name = "Second security group"
  description = "Allows instances to access port 80 and port 22"

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["172.31.0.0/24"]
  }

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["172.31.0.0/24"]
  }

  egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
  }
}

# create a security group for ELB 
resource "aws_security_group" "ELB_sec_grp" {
  name = "ELB security group"
  description = "Allows port 80 ingress from anywhere"

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  } 
}

# Create a new load balancer
resource "aws_elb" "elb" {
  name = "ELB-web"
  subnets = ["${aws_subnet.public_subnet_2.id}", "${aws_subnet.public_subnet_3.id}"]
  security_groups = ["${aws_security_group.ELB_sec_grp.id}"]

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    target = "HTTP:80/"
    interval = 30
  }

  instances = ["${aws_instance.webserver-b.id}", "${aws_instance.webserver-c.id} "]
  connection_draining = true
  connection_draining_timeout = 60

  tags {
    Name = "ELB for instances created"
  }
}

#Create a new instance to run web services(linux)
resource "aws_instance" "webserver-b" {
    ami = "ami-5ec1673e"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.private_subnet_2.id}"
    associate_public_ip_address = false
    vpc_security_group_ids = ["${aws_security_group.sec_grp_2.id}"]
    key_name = "cit360"
    tags {
        Name = "webserver-b"
        Service = "curriculum "
    }
}
#Create a 2nd instance to run web services(linux)
resource "aws_instance" "webserver-c" {
    ami = "ami-5ec1673e"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.private_subnet_3.id}"
    associate_public_ip_address = false
    vpc_security_group_ids = ["${aws_security_group.sec_grp_2.id}"]

    key_name = "cit360"
    tags {
        Name = "webserver-c"
        Service = "curriculum "
    }
}

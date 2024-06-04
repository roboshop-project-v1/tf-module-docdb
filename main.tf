resource "aws_docdb_subnet_group" "main" {
  name       = "${local.name_prefix}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = var.tags
}



resource "aws_security_group" "docdb" {
  name        = "${local.name_prefix}-sg"
  description = "${local.name_prefix}-sg"
  vpc_id      = var.vpc_id
  tags = var.tags
}



resource "aws_security_group_rule" "main" {
  type              = "ingress"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  cidr_blocks       = var.sg_ingress_cidr
  security_group_id = aws_security_group.docdb.id
}


resource "aws_vpc_security_group_egress_rule" "main" {
  security_group_id = aws_security_group.docdb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}




resource "aws_docdb_cluster" "main" {
  cluster_identifier      = "${local.name_prefix}-cluster"
  engine                  = "docdb"
  master_username         = data.aws_ssm_parameter.master_username.value
  master_password         = data.aws_ssm_parameter.master_password.value
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window
  skip_final_snapshot     = var.skip_final_snapshot
  db_subnet_group_name = aws_docdb_subnet_group.main.name
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.main.name
  vpc_security_group_ids = [aws_security_group.docdb.id]
  tags = var.tags
  engine_version = var.engine_version
}



resource "aws_docdb_cluster_parameter_group" "main" {
  family      = var.family
  name        = "${local.name_prefix}-pg"
  description ="${local.name_prefix}-pg"
  tags = var.tags
}

resource "aws_docdb_cluster_instance" "main" {
  count              = var.instance_count
  identifier         = "${local.name_prefix}-clusterinstance-${count.index}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = var.instance_class
}
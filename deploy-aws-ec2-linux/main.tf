provider "vault" {
    address = "http://localhost:8200"
    token = "<unsealtokenfromvault>"
}

data "vault_generic_secret" "aws_auth" {
    path = "secret/<keyname>"
}

provider "aws" {
    region = "us-west-2"
    access_key = data.vault_generic_secret.aws_auth.data["access_key"]
    secret_key = data.vault_generic_secret.aws_auth.data["secret_key"]
}

data "aws_ami" "linux" {
    owners      = ["amazon"]
    most_recent = true
    filter {
        name   = "name"
        values = ["amzn2-ami-hvm-2.0*"]
    }
    filter {
        name   = "architecture"
        values = ["x86_64"]
    }
}

resource "aws_instance" "linux" {
    ami           = data.aws_ami.linux.image_id
    instance_type = "t2.micro"
    vpc_security_group_ids = ["sg-id","sg-id2","sg-id3"]
    get_password_data = true
    subnet_id = "subnet-id"
    key_name = "<secretkey>"
    tags = {
        Name = "<vmname>"
    }
    user_data = <<EOF
        #!/bin/bash
        yum update -y
        yum -y install iscsi-initiator-utils
        yum -y install lsscsi
        yum -y install device-mapper-multipath
        service iscsid start
        amazon-linux-extras install epel -y
        yum install sshpass -y
        iqn=`awk -F= '{ print $2 }' /etc/iscsi/initiatorname.iscsi`
        sshpass -p pureuser ssh  -oStrictHostKeyChecking=no pureuser@<ctmgmt-vip>> purehost create <hostnameforpure> --iqnlist $iqn
        sshpass -p pureuser ssh  -oStrictHostKeyChecking=no pureuser@<ctmgmt-vip> purehost connect --vol <purevolname> <hostnameforpure>
        iscsiadm -m iface -I iscsi0 -o new
        iscsiadm -m iface -I iscsi1 -o new
        iscsiadm -m iface -I iscsi2 -o new
        iscsiadm -m iface -I iscsi3 -o new
        iscsiadm -m discovery -t st -p <ct0-iscsi-ip>:3260
        iscsiadm -m node -p <ct0-iscsi-ip> --login
        iscsiadm -m node -p <ct1-iscsi-ip> --login
        iscsiadm -m node -L automatic
        mpathconf --enable --with_multipathd y
        service multipathd restart
        mkdir /mnt/cbsvol
        disk=`multipath -ll|awk '{print $1;exit}'`
        mount /dev/mapper/$disk /mnt/cbsvol
        EOF
}

output "public_dns" {
    value = aws_instance.linux.*.public_dns
}
output "public_ip" {
    value = aws_instance.linux.*.public_ip
}
output "name" {
    value = aws_instance.linux.*.tags.Name
}

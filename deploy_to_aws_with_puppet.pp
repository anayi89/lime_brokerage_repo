ec2_instance { 'redhat-7':
        ensure            => 'running',
        availability_zone => 'us-east-1a',
        image_id          => 'ami-0dccf86d354af8ce3',
        instance_type     => 't2.micro',
        key_name          => 'puppet_key',
        monitoring        => 'false',
        region            => 'us-east-1',
        security_groups   => ['puppet_ec2_securitygroup'],
        subnet            => 'subnet-e8fc2aa4'
}

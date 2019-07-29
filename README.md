# EC2InstanceConnect
 Terraform configuration for a simple setup for using EC2 instance connect

This sets up a single EC2 instance a basic IAM policy to allow users to push their public key to the instance in order to connect over SSH.

Documentation for how to connect using EC2 instance connect can be found at https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-connect-methods.html#ec2-instance-connect-connecting-aws-cli

You will need to pass in the user_source_cidr variable, either at runtime or in a .tfvars file, to setup the ingress security group rule for SSH.

To-Do for Future Versions:

 * Get the EC2 instance identifier working so the IAM policy does not have to apply to all EC2 resources
 * Add more variables for further user customization/automation 

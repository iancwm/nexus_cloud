# Deployment Security & Connectivity Specifications

## Objective
Enhance the security posture of the Nexus-Cloud workspace by removing the need for open SSH ports (Port 22) and providing a seamless, automated VS Code connection experience.

## Connectivity Architecture: AWS SSM Session Manager
*   **Strategy**: Transition from direct SSH to **AWS Systems Manager (SSM) Session Manager**.
*   **Security Benefits**: 
    *   No open inbound ports (Port 22 closed in Security Groups).
    *   Authentication handled via IAM (no managed SSH keys required).
    *   Full audit logging of session commands in CloudWatch.
*   **Mechanism**:
    *   Add `AmazonSSMManagedInstanceCore` policy to the Instance Role.
    *   Install the SSM Agent on the EC2 instance (pre-installed on most Ubuntu AMIs).

## VS Code Friendly Connectivity
*   **Goal**: Allow `ssh nexus-workspace` to work natively in VS Code without manual IP updates.
*   **Proxy Solution**: Use the AWS CLI's `ssm start-session` as a **ProxyCommand** in the local SSH config.
*   **Automation**: 
    *   Update `nexus_wizard.py` to optionally generate/update the local `~/.ssh/config`.
    *   Create a `just ssm-setup` recipe to configure the local machine.

## VPC Enhancements
*   **Private Isolation**: Ensure the instance resides in a subnet where traffic is explicitly controlled.
*   **VPC Endpoints (Optional)**: If full isolation is required, add VPC Endpoints for SSM, SSMMessages, and EC2Messages to allow connectivity without an IGW.

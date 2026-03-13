import os
import sys
import subprocess
import json
import boto3
import click
import yaml
from botocore.exceptions import NoCredentialsError, ClientError

# --- Constants ---
CONFIG_FILE = "config.yaml"
SECRET_NAME = "nexus-cloud/ai-api-keys"

# --- Utility Functions ---

def check_command(cmd):
    """Verify if a command is available in the shell."""
    try:
        subprocess.run([cmd, "--version"], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

def get_aws_client(service, region=None):
    """Initialize a boto3 client."""
    return boto3.client(service, region_name=region)

# --- Commands ---

@click.group()
def cli():
    """Nexus-Cloud AI Workspace Setup Wizard & Debugger."""
    pass

@cli.command()
def wizard():
    """Interactive wizard to configure the workspace."""
    click.clear()
    click.secho("\n--- 🚀 Nexus-Cloud Setup Wizard ---", fg="cyan", bold=True)
    
    click.secho("\n⚠️  IMPORTANT: PRE-REQUISITES & SECURITY", fg="yellow", bold=True)
    click.echo("1. Ensure your Cloud CLI (e.g., 'aws') is configured with an ")
    click.secho("   ADMIN ACCOUNT", fg="red", bold=True, nl=False)
    click.echo(" to avoid permission errors during provisioning.")
    click.echo("2. ")
    click.secho("NEVER MODIFY FILES MANUALLY", fg="red", bold=True, nl=False)
    click.echo(" (e.g., Terraform state or config files).")
    click.echo("   Use this wizard or 'just' commands to manage your workspace.")
    
    if not click.confirm("\nDo you confirm your account has Admin rights and you will avoid manual edits?"):
        click.secho("Aborting. Please ensure your environment is ready.", fg="red")
        return

    click.echo("\n" + "="*50)
    click.echo("Follow the prompts to configure your high-performance workspace.")
    click.echo("="*50 + "\n")

    # 1. AWS Configuration
    click.secho("Step 1: AWS Configuration", fg="green", bold=True)
    click.echo("This configures the default region and authentication fallback.\n")
    
    region = click.prompt("AWS Region (Press Enter for 'us-east-1')", default="us-east-1", show_default=False)
    access_key = click.prompt("AWS Access Key ID (Leave empty to use existing local CLI auth)", default="", show_default=False)
    secret_key = click.prompt("AWS Secret Access Key", default="", show_default=False, hide_input=True)

    # 2. AI Tooling Configuration
    click.echo("\n" + "="*50)
    click.secho("Step 2: AI Tooling Configuration", fg="green", bold=True)
    click.secho("Tip: Leave these blank to use your Pro/Plus Subscriptions (OAuth).", fg="yellow")
    click.echo("These keys will be stored in AWS Secrets Manager.\n")
    
    ant_key = click.prompt("Anthropic API Key (Claude Code)", default="", show_default=False)
    openai_key = click.prompt("OpenAI API Key (Codex/OpenCode)", default="", show_default=False)
    gemini_key = click.prompt("Gemini API Key", default="", show_default=False)

    # 3. Git Configuration
    click.echo("\n" + "="*50)
    click.secho("Step 3: Git Configuration", fg="green", bold=True)
    click.echo("This will configure your Git identity on the workspace.\n")
    git_name = click.prompt("Git User Name", default="Nexus User")
    git_email = click.prompt("Git User Email", default="nexus@example.com")

    # 4. Construct the YAML
    config_data = {
        "aws": {
            "region": region,
            "instance_type": "t3.large"
        },
        "llm_apis": {
            "anthropic_api_key": ant_key,
            "openai_api_key": openai_key,
            "gemini_api_key": gemini_key
        },
        "git": {
            "user_name": git_name,
            "user_email": git_email
        }
    }

    # Save to config.yaml
    with open(CONFIG_FILE, "w") as f:
        yaml.dump(config_data, f, default_flow_style=False)
    
    click.secho(f"\n✅ SUCCESS: {CONFIG_FILE} generated locally.", fg="green")

    # 4. Upload to Secrets Manager (Optional)
    click.echo("\n" + "="*50)
    if click.confirm("Would you like to upload these API keys to AWS Secrets Manager now?"):
        try:
            # Set credentials temporarily for boto3 if provided
            if access_key and secret_key:
                os.environ["AWS_ACCESS_KEY_ID"] = access_key
                os.environ["AWS_SECRET_ACCESS_KEY"] = secret_key

            client = get_aws_client("secretsmanager", region=region)
            secret_payload = {
                "ANTHROPIC_API_KEY": ant_key,
                "OPENAI_API_KEY": openai_key,
                "GEMINI_API_KEY": gemini_key,
                "GIT_USER_NAME": git_name,
                "GIT_USER_EMAIL": git_email
            }

            try:
                client.put_secret_value(SecretId=SECRET_NAME, SecretString=json.dumps(secret_payload))
                click.secho(f"✅ Secrets successfully updated in {SECRET_NAME}.", fg="green")
            except client.exceptions.ResourceNotFoundException:
                client.create_secret(Name=SECRET_NAME, SecretString=json.dumps(secret_payload))
                click.secho(f"✅ Secret '{SECRET_NAME}' created in {region}.", fg="green")
        except Exception as e:
            click.secho(f"❌ Failed to upload secrets: {e}", fg="red")

    click.secho("\n" + "="*50)
    click.secho("--- Wizard Complete ---", fg="cyan", bold=True)
    click.echo("Your environment is now ready.")
    click.echo("1. Run 'just debug' to verify connectivity.")
    click.echo("2. Run 'just build' to provision your workspace.")

@cli.command()
def debug():
    """Run diagnostics to detect setup errors."""
    click.secho("\n--- 🔍 Nexus-Cloud Debugger ---", fg="cyan", bold=True)
    
    # 1. Dependency Check
    click.echo("\n[1] Checking Dependencies...")
    for cmd in ["terraform", "uv", "just", "aws"]:
        if check_command(cmd):
            click.echo(f"  ✅ {cmd}: Found")
        else:
            click.secho(f"  ❌ {cmd}: NOT FOUND", fg="red")
            if cmd == "terraform":
                click.echo("      Hint: Install via 'sudo apt install terraform' or equivalent.")

    # 2. AWS Connectivity Check
    click.echo("\n[2] Checking AWS Connectivity...")
    try:
        sts = get_aws_client("sts")
        identity = sts.get_caller_identity()
        click.echo(f"  ✅ Connected as: {identity['Arn']}")
    except (NoCredentialsError, ClientError) as e:
        click.secho(f"  ❌ AWS Connectivity Failed: {e}", fg="red")
        click.echo("      Hint: Run 'aws configure' or provide keys in the wizard.")

    # 3. Secret Check
    click.echo("\n[3] Checking AWS Secrets Manager...")
    try:
        sm = get_aws_client("secretsmanager")
        sm.describe_secret(SecretId=SECRET_NAME)
        click.echo(f"  ✅ Secret '{SECRET_NAME}': Found")
    except ClientError:
        click.secho(f"  ❌ Secret '{SECRET_NAME}': NOT FOUND", fg="yellow")
        click.echo("      Hint: Run 'just secrets' or use the wizard to create it.")

    # 4. Terraform State Check
    click.echo("\n[4] Checking Infrastructure State...")
    if os.path.exists("terraform.tfstate"):
        try:
            output = subprocess.run(["terraform", "output", "-json"], capture_output=True, text=True)
            if output.stdout.strip() != "{}":
                click.echo("  ✅ Instance state found.")
            else:
                click.echo("  ⚠️ Infrastructure initialized but no resources found.")
        except Exception:
            click.echo("  ❌ Failed to read terraform state.")
    else:
        click.echo("  ℹ️ terraform.tfstate not found. Workspace not yet deployed.")

    click.secho("\n--- Debugger Complete ---", fg="cyan", bold=True)

if __name__ == "__main__":
    cli()

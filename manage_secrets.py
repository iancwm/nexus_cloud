import boto3
import json
import click
import os

SECRET_NAME = "nexus-cloud/ai-api-keys"

@click.group()
def cli():
    pass

@cli.command()
@click.option('--anthropic', help='Anthropic API Key')
@click.option('--openai', help='OpenAI API Key')
@click.option('--gemini', help='Gemini API Key')
@click.option('--region', default='us-east-1', help='AWS Region')
def set_keys(anthropic, openai, gemini, region):
    """Securely upload API keys to AWS Secrets Manager."""
    client = boto3.client('secretsmanager', region_name=region)
    
    # Try to get existing secret first
    try:
        response = client.get_secret_value(SecretId=SECRET_NAME)
        current_data = json.loads(response['SecretString'])
    except client.exceptions.ResourceNotFoundException:
        current_data = {}

    # Update with new values
    if anthropic: current_data['ANTHROPIC_API_KEY'] = anthropic
    if openai: current_data['OPENAI_API_KEY'] = openai
    if gemini: current_data['GEMINI_API_KEY'] = gemini

    # Put secret back
    try:
        client.put_secret_value(SecretId=SECRET_NAME, SecretString=json.dumps(current_data))
        click.echo(f"Successfully updated secrets in {SECRET_NAME}")
    except client.exceptions.ResourceNotFoundException:
        client.create_secret(Name=SECRET_NAME, SecretString=json.dumps(current_data))
        click.echo(f"Successfully created secrets in {SECRET_NAME}")

if __name__ == '__main__':
    cli()

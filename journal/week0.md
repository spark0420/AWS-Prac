# Week 0 — Billing and Architecture

## Recreate Conceptual Diagram in Lucid Charts or on a Napkin
- A conceptual model is a representation of a system. It consists of concepts used to help people know, understand, or simulate a subject the model represents.
<img src = "images/ConceptualDiagram.png" >
## Recreate Logical Architectual Diagram in Lucid Charts

## Create an Admin User

## Use CloudShell

## Generate AWS Credentials

## Installed AWS CLI

## Create a AWS Billing Alarm

## Create a AWS Budget

1. Set a Billing alarm on my AWS account
- The detailed syntax and commends are in aws/json folder

2. Set a AWS Budget 
- Set two AWS bedgets, one for monthly spend and one for credit spend
- This can be set through AWS console or CLI commends that is is aws/json folder
- The syntax is also included in the folder

3. Generating AWS Credentials 
- Created an IAM user 'Scarlett' for my account

4. Using CloudShell
- All inital setup to use CLI with Gitpod is shown in gitpod.yml file
---------------------------------------------------------------
tasks:
  - name: aws-cli
    env:
      AWS_CLI_AUTO_PROMPT: on-partial
    init: |
      cd /workspace
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip
      sudo ./aws/install
      cd $THEIA_WORKSPACE_ROOT
---------------------------------------------------------------

5. Conceptual Architecture Diagram or your Napkins
- coming 
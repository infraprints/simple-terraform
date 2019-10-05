# Prototype CodePipeline Terraform Repository

A repository for terraform execution in a Codepipeline task. This repository is part of an original experiment

I wanted to have an terraform executor that met the following requirements:

- Use official terraform docker image (`hashicorp/terraform:light`)
- No external dependencies or custom images (e.g. terragrunt, astro, etc)
- Customizable execution process with minimal overhead
- Support in-repository modules
- No credential management (AWS Codepipeline execution)
- Multiple AWS environments within a single repository
- No single state file, state file per component (controlled by `terraform.tf` file)
- State files map to location in repository
- Potential for custom IAM role per component (as opposed to single access permission)

This was a quick prototype to see if I would be able to get something rough running, with the shell executor being just the bare essentials that I need.

## Issues with the final result

There are a couple of issues I noted when setting this up, and the eventual improvements made to the later executors. I have listed them below:

- CodePipeline requires cloudwatch to provide notifications on failure
- CodeBuild log for the `terraform plan/show` outputs is not very pretty
- CodePipeline is limited to a single branch, impacting the idea of 'preview' builds
- Shell based executors are simple, but require maintenance
- YAML Executors (see GitLab / GitHub Actions / CircleCI) have isolated executor for each component
- Deployments to 2 or more accounts requires a 'GitFlow' style approach, which has a lot of overhead
- Restricting permissions on the component level requires a fair bit of extra work, and isn't really sound
- Control options are handled by files (e.g. `ORDER`, `IGNORE`, `APPLY_ONLY`), which doesn't lend itself to customization well

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

It is nice to have everything in AWS, with serverless architecture but I find the limitations are a big issue. If I was starting from scratch, I would be interested in the idea of deploying a GitLab + GitLabCI architecture in AWS, then restricting IAM access by executors (that would be provisioned by AWS Lambda).

The big problems I have with this style of terraform executor is the edge cases. I'll mention three that have bugged me the most:

### Deployments into another AWS ACcount

Allowing another team (or individual) to have a component (e.g. teraform deployment) that exists within an account I own. I would want to restrict access for that role, and keep knowledge of that terraform within my infrastructure repository. Also wouldn't want to require my approval on every PR, but at the same time not allow free reign within the AWS account.

It is an option to just expose a role in an account, then allow the terraform+executor to be handled by the team in another repo/executor. This can mean back and forth a bit, as the IAM permissions for that role need to be fine tuned

### Existing infrastructure / failed deployments

This can happen when you are not using uniqely named resources (e.g. `my-s3-bucket-x2r1`), where terraform will fail when it encounters an existing resource. Failures can also happen when working with a non-terraform managed resource (e.g. IAM policy usages). When using a codepipeline executor, everything is in a single log file so it can be difficult to know:

1) Who failed?
2) What resource had failed?
3) Where is that in the repository?

### Cross-cutting concerns

Deployments with codepipeline executors do not work well for cross-cutting concerns. If I want to deploy something into every single AWS account (such as an IAM role or S3 bucket), it just doesn't work well. I don't get the advantages of parallel execution, and a failure midway cannot be reverted easily. Permissions are also way too open for my taste, in that the single executor is running in every single account within any real guard-rails.

At least with an external ID per account role, with isolated execution (in say GitLabCI / CircleCI) I have more confidence that I won't see misconfiguration in an account.

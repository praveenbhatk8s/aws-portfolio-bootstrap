output "state_bucket" {
  description = "S3 bucket for every project's Terraform state (key prefix = repo name)."
  value       = aws_s3_bucket.tfstate.bucket
}

output "github_oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github.arn
}

output "plan_role_arns" {
  description = "Put in each repo as the AWS_PLAN_ROLE_ARN Actions variable."
  value       = { for repo, role in aws_iam_role.plan : repo => role.arn }
}

output "apply_role_arns" {
  description = "Put in each repo as the AWS_APPLY_ROLE_ARN Actions variable."
  value       = { for repo, role in aws_iam_role.apply : repo => role.arn }
}

output "backend_snippet" {
  description = "Paste into each project's versions.tf (replace <repo>)."
  value       = <<-EOT
    backend "s3" {
      bucket       = "${aws_s3_bucket.tfstate.bucket}"
      key          = "<repo>/terraform.tfstate"
      region       = "${var.region}"
      use_lockfile = true
      encrypt      = true
    }
  EOT
}

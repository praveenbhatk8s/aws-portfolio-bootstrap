variable "region" {
  description = "Single region for all portfolio work."
  type        = string
  default     = "eu-central-1"
}

variable "github_owner" {
  description = "GitHub user or org that owns the project repos."
  type        = string
  default     = "praveenbhatk8s"
}

variable "project_repos" {
  description = "Repos that get a GitHub Actions plan role and apply role, each scoped to its own state prefix."
  type        = set(string)
  default = [
    "amtpilot-ec2",
    "wildlife-gallery",
    "restore-verified-backups",
    "job-pipeline-api",
  ]
}

variable "apply_environment" {
  description = "GitHub Actions environment that apply jobs must run in (add required reviewers to it in GitHub)."
  type        = string
  default     = "aws-portfolio"
}

variable "budget_email" {
  description = "Email address for the monthly budget alerts."
  type        = string
}

variable "budget_limit_usd" {
  description = "Monthly cost budget in USD."
  type        = number
  default     = 20
}

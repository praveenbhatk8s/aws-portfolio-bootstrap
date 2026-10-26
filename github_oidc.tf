# GitHub Actions authenticates to AWS with short-lived OIDC tokens. No access keys are stored in GitHub.
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # thumbprint_list is optional: AWS validates GitHub's certificate against its own trusted CAs.
}

# ---------- Plan role: any pull request in the repo, read-only ----------
data "aws_iam_policy_document" "plan_trust" {
  for_each = var.project_repos

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_owner}/${each.value}:pull_request",
        "repo:${var.github_owner}/${each.value}:ref:refs/heads/main",
      ]
    }
  }
}

resource "aws_iam_role" "plan" {
  for_each             = var.project_repos
  name                 = "gha-${each.value}-plan"
  description          = "GitHub Actions terraform plan for ${each.value} (read-only)"
  assume_role_policy   = data.aws_iam_policy_document.plan_trust[each.value].json
  max_session_duration = 3600
}

resource "aws_iam_role_policy_attachment" "plan_readonly" {
  for_each   = var.project_repos
  role       = aws_iam_role.plan[each.value].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ---------- Apply role: only jobs running in the protected GitHub environment ----------
data "aws_iam_policy_document" "apply_trust" {
  for_each = var.project_repos

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}/${each.value}:environment:${var.apply_environment}"]
    }
  }
}

resource "aws_iam_role" "apply" {
  for_each             = var.project_repos
  name                 = "gha-${each.value}-apply"
  description          = "GitHub Actions terraform apply for ${each.value}"
  assume_role_policy   = data.aws_iam_policy_document.apply_trust[each.value].json
  max_session_duration = 3600
}

# Projects create their own IAM roles, so apply needs broad rights. The guardrails are the
# trust policy (protected environment only), the per-repo state prefix, and the budget alert.
# Tightening this per project is a deliberate later step and a good README section.
resource "aws_iam_role_policy_attachment" "apply_admin" {
  for_each   = var.project_repos
  role       = aws_iam_role.apply[each.value].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ---------- State access: each repo can only touch its own state prefix ----------
data "aws_iam_policy_document" "state_access" {
  for_each = var.project_repos

  statement {
    sid       = "ListOwnPrefix"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.tfstate.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${each.value}/*"]
    }
  }

  statement {
    sid       = "ReadWriteOwnState"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.tfstate.arn}/${each.value}/*"]
  }
}

resource "aws_iam_role_policy" "plan_state" {
  for_each = var.project_repos
  name     = "tfstate-${each.value}"
  role     = aws_iam_role.plan[each.value].id
  policy   = data.aws_iam_policy_document.state_access[each.value].json
}

resource "aws_iam_role_policy" "apply_state" {
  for_each = var.project_repos
  name     = "tfstate-${each.value}"
  role     = aws_iam_role.apply[each.value].id
  policy   = data.aws_iam_policy_document.state_access[each.value].json
}

export AWS_PROFILE ?= portfolio

.PHONY: init fmt validate scan plan apply output login

login:
	aws sso login

init:
	terraform init

fmt:
	terraform fmt -recursive

validate: init
	terraform validate

scan:
	trivy config --severity HIGH,CRITICAL .

plan: validate
	terraform plan -out=tfplan

apply:
	terraform apply tfplan

output:
	terraform output

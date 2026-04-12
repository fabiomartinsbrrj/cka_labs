KEY_NAME ?= cka-key
NUKE_CONFIG ?= nuke-config.yaml

.PHONY: init plan apply destroy nuke

init:
	terraform init

plan:
	terraform plan -var="key_name=$(KEY_NAME)"

apply:
	terraform apply -auto-approve -var="key_name=$(KEY_NAME)"

destroy:
	terraform destroy -auto-approve -var="key_name=$(KEY_NAME)"

nuke:
	aws-nuke run --config $(NUKE_CONFIG) --no-dry-run

nuke-dry:
	aws-nuke run --config $(NUKE_CONFIG)

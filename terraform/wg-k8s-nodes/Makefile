
all:
	terraform apply

conf:
	@terraform output -json configs | jq -r '."${HOST}".conf'

install:
	@./install.sh

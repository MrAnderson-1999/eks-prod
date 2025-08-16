Empty Environment deployment
# 1. Deploy core infrastructure (private)
cd infrastructure/terragrunt/non-prod
terragrunt run-all apply

# 2. Enable public access temporarily  
./scripts/enable-public-api.sh

# 3. Deploy applications
cd applications/alb-controller
terraform apply

cd ../argocd
terraform apply

# 4. Disable public access
./scripts/disable-public-api.sh


aws eks update-kubeconfig --region us-west-2 --name eks-security-non-prod
output "cluster_name" {
  value = module.doct_cbd3375_eks.cluster_name
}

output "cluster_identity_oidc_issuer" {
  value = module.doct_cbd3375_eks.oidc_provider
}

output "cluster_identity_oidc_issuer_arn" {
  value = module.doct_cbd3375_eks.oidc_provider_arn
}

output "cluster_id" {
  value = module.doct_cbd3375_eks.cluster_id  
}
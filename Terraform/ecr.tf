# Create ECR Repositories
resource "aws_ecr_repository" "repo" {
  for_each             = toset(var.ecr_repo_names)
  name                 = each.key
  image_tag_mutability = "MUTABLE" # Use "IMMUTABLE" for production

  image_scanning_configuration {
    scan_on_push = true # Enable automatic vulnerability scanning on push :cite[4]:cite[6]
  }

  encryption_configuration {
    encryption_type = "AES256" # Server-side encryption
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Optional: Lifecycle Policy to clean up old images
resource "aws_ecr_lifecycle_policy" "repo_policy" {
  for_each   = toset(var.ecr_repo_names)
  repository = aws_ecr_repository.repo[each.key].name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 30 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 30
      }
      action = {
        type = "expire"
      }
    }]
  })
}
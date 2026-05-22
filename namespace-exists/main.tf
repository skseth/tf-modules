
data "kubernetes_all_namespaces" "allns" {}

# This is used to see if we are in plan or apply phase
# we don't want to fail in plan
resource "terraform_data" "phase_detector" {
  # This value is only determined during the apply step
  input = timestamp() 
}

resource "terraform_data" "exists" {
  lifecycle {
    precondition {
      # This condition must be TRUE to pass; if FALSE, it fails.
      # by using terraform_data.phase_detector.output != "" we postpone the evaluation to the apply phase
      condition     = terraform_data.phase_detector.output != "" || length(setsubtract(var.namespaces, data.kubernetes_all_namespaces.allns.namespaces )) == 0
      error_message = "At one of the namespaces ${join(", ", var.namespaces)} does not exist."
    }
  }

  depends_on = [ terraform_data.phase_detector ]
}
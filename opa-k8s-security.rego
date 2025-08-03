package main

# Enforce that Services use NodePort type
# NodePort exposes services on a static port on each node, providing external access
deny contains msg if {
    input.kind == "Service"
    input.spec.type != "NodePort"
    msg := "Service type should be NodePort"
}

# Ensure Deployment containers run as non-root user
# Running as root violates security best practices and increases attack surface
deny contains msg if {
    input.kind == "Deployment"
    
    # Check the first container's security context
    container := input.spec.template.spec.containers[0]
    not container.securityContext.runAsNonRoot == true
    
    msg := "Containers must not run as root - use runAsNonRoot within container security context"
}
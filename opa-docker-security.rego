package main

# List of common secret-related keywords to detect in environment variables
secrets_env := [
    "passwd",
    "password", 
    "pass",
    "secret",
    "key",
    "access",
    "api_key",
    "apikey",
    "token",
    "tkn"
]

# Deny storing secrets in environment variables
# This prevents hardcoded credentials from being exposed in container images
deny contains msg if {
    some i
    input[i].Cmd == "env"
    val := input[i].Value
    
    some env_val in val
    some secret_pattern in secrets_env
    contains(lower(env_val), secret_pattern)
    
    msg := sprintf("Line %d: Potential secret in ENV key found: %s", [i, val])
}

# Deny using 'latest' tag for base images  
# Using specific tags ensures reproducible builds and prevents unexpected changes
deny contains msg if {
    some i
    input[i].Cmd == "from"
    val := split(input[i].Value[0], ":")
    
    count(val) > 1
    contains(lower(val[1]), "latest")
    
    msg := sprintf("Line %d: do not use 'latest' tag for base images", [i])
}

# Prevent curl bashing - downloading scripts and piping directly to shell
# This is a security risk as it executes untrusted code without inspection
deny contains msg if {
    some i
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    
    matches := regex.find_all_string_submatch_n("(curl|wget)[^|^>]*[|>]", lower(val), -1)
    count(matches) > 0
    
    msg := sprintf("Line %d: Avoid curl bashing", [i])
}

# List of system package upgrade commands that should be avoided
upgrade_commands := [
    "apk upgrade",
    "apt-get upgrade", 
    "dist-upgrade",
]

# Prevent system package upgrades in containers
# Upgrades can introduce unexpected changes and increase image size
deny contains msg if {
    some i
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    
    some upgrade_cmd in upgrade_commands
    contains(val, upgrade_cmd)
    
    msg := sprintf("Line: %d: Do not upgrade your system packages", [i])
}

# Prevent use of ADD command
# COPY is preferred over ADD as it's more predictable and secure
deny contains msg if {
    some i
    input[i].Cmd == "add"
    msg := sprintf("Line %d: Use COPY instead of ADD", [i])
}

# Check if any USER directive exists in the Dockerfile
any_user if {
    some i
    input[i].Cmd == "user"
}

# Ensure containers don't run as root by default
# Running as root violates the principle of least privilege
deny contains msg if {
    not any_user
    msg := "Do not run as root, use USER instead"
}

# List of forbidden user accounts that are equivalent to root
forbidden_users := [
    "root",
    "toor", 
    "0"
]

# Prevent running as root or root-equivalent users
# These users have elevated privileges that containers shouldn't need
deny contains msg if {
    some i
    input[i].Cmd == "user"
    val := input[i].Value
    
    some user_val in val
    some forbidden_user in forbidden_users
    contains(lower(user_val), forbidden_user)
    
    msg := sprintf("Line %d: Do not run as root: %s", [i, val])
}

# Prevent use of sudo command in RUN instructions
# Sudo shouldn't be needed in container builds and indicates privilege escalation
deny contains msg if {
    some i
    input[i].Cmd == "run"
    val := concat(" ", input[i].Value)
    contains(lower(val), "sudo")
    
    msg := sprintf("Line %d: Do not use 'sudo' command", [i])
}
#!/bin/bash
#
# validate-kube-commands.sh
# =========================
#
# A Claude Code PreToolUse hook that enforces safe kubectl and helm command usage
# by requiring explicit context and namespace specifications.
#
# PURPOSE
# -------
# Prevents accidental operations against wrong Kubernetes clusters or namespaces
# by blocking kubectl/helm commands that don't explicitly specify allowed contexts
# and the required namespace.
#
# REQUIREMENTS
# ------------
# - jq (for parsing CLAUDE_TOOL_INPUT JSON)
# - awk (for flag extraction)
# - grep (for command detection)
#
# CONFIGURATION
# -------------
# Allowed contexts (modify ALLOWED_CONTEXTS below):
#   - cw4637-dev-rno2a
#   - cw4637-dev-us-e-01a
#   - dev-rno2a
#
# Required namespace (modify REQUIRED_NAMESPACE below):
#   - ace-inference
#
# CONTEXT FLAGS
# -------------
# - kubectl uses: --context or --context=<value>
# - helm uses:    --kube-context or --kube-context=<value>
#
# NAMESPACE FLAGS
# ---------------
# Both tools accept: -n <value>, --namespace <value>, or --namespace=<value>
#
# INSTALLATION
# ------------
# 1. Place this script in ~/.claude/hooks/
# 2. Make executable: chmod +x ~/.claude/hooks/validate-kube-commands.sh
# 3. Add to ~/.claude/settings.json:
#
#    "hooks": {
#      "PreToolUse": [
#        {
#          "matcher": "Bash",
#          "hooks": [
#            {
#              "type": "command",
#              "command": "/Users/<you>/.claude/hooks/validate-kube-commands.sh"
#            }
#          ]
#        }
#      ]
#    }
#
# TEST CASES
# ----------
# Run these to verify the hook works correctly:
#
# # Test 1: kubectl without context - should BLOCK
# CLAUDE_TOOL_INPUT='{"command": "kubectl get pods"}' ./validate-kube-commands.sh
# # Expected: BLOCKED: kubectl commands must explicitly specify --context
#
# # Test 2: kubectl with space-separated valid context - should PASS
# CLAUDE_TOOL_INPUT='{"command": "kubectl --context dev-rno2a get pods -n ace-inference"}' ./validate-kube-commands.sh
# # Expected: exit 0
#
# # Test 3: kubectl with = valid context - should PASS
# CLAUDE_TOOL_INPUT='{"command": "kubectl --context=dev-rno2a get pods -n ace-inference"}' ./validate-kube-commands.sh
# # Expected: exit 0
#
# # Test 4: helm without kube-context - should BLOCK
# CLAUDE_TOOL_INPUT='{"command": "helm upgrade --dry-run myrelease ./chart"}' ./validate-kube-commands.sh
# # Expected: BLOCKED: helm commands must explicitly specify --kube-context
#
# # Test 5: helm with valid kube-context - should PASS
# CLAUDE_TOOL_INPUT='{"command": "helm upgrade --dry-run --kube-context=dev-rno2a myrelease ./chart -n ace-inference"}' ./validate-kube-commands.sh
# # Expected: exit 0
#
# # Test 6: wrong namespace - should BLOCK
# CLAUDE_TOOL_INPUT='{"command": "kubectl --context=dev-rno2a get pods -n default"}' ./validate-kube-commands.sh
# # Expected: BLOCKED: Namespace 'default' is not allowed
#
# # Test 7: invalid context - should BLOCK
# CLAUDE_TOOL_INPUT='{"command": "kubectl --context=production get pods -n ace-inference"}' ./validate-kube-commands.sh
# # Expected: BLOCKED: Context 'production' is not allowed
#
# # Test 8: non-kube command - should PASS (ignored)
# CLAUDE_TOOL_INPUT='{"command": "ls -la"}' ./validate-kube-commands.sh
# # Expected: exit 0
#
# # Test 9: helm with space-separated kube-context - should PASS
# CLAUDE_TOOL_INPUT='{"command": "helm upgrade --dry-run --kube-context cw4637-dev-rno2a myrelease ./chart --namespace ace-inference"}' ./validate-kube-commands.sh
# # Expected: exit 0
#
# # Test 10: kubectl with --namespace= format - should PASS
# CLAUDE_TOOL_INPUT='{"command": "kubectl --context=dev-rno2a get pods --namespace=ace-inference"}' ./validate-kube-commands.sh
# # Expected: exit 0
#
# BEHAVIOR
# --------
# - Exit 0: Command is allowed (either valid kube command or non-kube command)
# - Exit 1: Command is blocked (outputs reason to stderr-like message)
#
# The hook outputs a BLOCKED message explaining why the command was rejected,
# which Claude Code displays to help the user correct their command.
#

set -euo pipefail

# =============================================================================
# CONFIGURATION - Modify these values to match your environment
# =============================================================================

# Space-separated list of allowed Kubernetes contexts
ALLOWED_CONTEXTS="cw4637-dev-rno2a cw4637-dev-us-e-01a dev-rno2a"

# Required namespace for all kubectl/helm operations
REQUIRED_NAMESPACE="ace-inference"

# =============================================================================
# MAIN SCRIPT - Generally no need to modify below this line
# =============================================================================

# Extract the command from CLAUDE_TOOL_INPUT (JSON with "command" field)
# Claude Code sets this environment variable with the tool input as JSON
COMMAND=$(echo "$CLAUDE_TOOL_INPUT" | jq -r '.command // empty')

# If no command found, allow (not a Bash tool call we care about)
if [[ -z "$COMMAND" ]]; then
    exit 0
fi

# Determine if this is kubectl, helm, or neither
# Pattern matches: start of string, whitespace, semicolon, &&, or || followed by the command
IS_KUBECTL=false
IS_HELM=false

if echo "$COMMAND" | grep -qE '(^|[[:space:]]|;|&&|\|\|)kubectl[[:space:]]'; then
    IS_KUBECTL=true
fi

if echo "$COMMAND" | grep -qE '(^|[[:space:]]|;|&&|\|\|)helm[[:space:]]'; then
    IS_HELM=true
fi

# Exit early if neither kubectl nor helm - allow the command
if [[ "$IS_KUBECTL" != "true" && "$IS_HELM" != "true" ]]; then
    exit 0
fi

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

# Extract a flag value from a command string
# Handles both --flag=value and --flag value formats
# Arguments:
#   $1 - The full command string
#   $2 - The flag to search for (e.g., "--context" or "--kube-context")
# Returns:
#   The flag value, or empty string if not found
extract_flag_value() {
    local cmd="$1"
    local flag="$2"
    local flag_len=$((${#flag} + 1))  # length of flag + 1 for the = sign

    echo "$cmd" | awk -v flag="$flag" -v flag_len="$flag_len" '{
        for(i=1; i<=NF; i++) {
            # Check for --flag=value format
            if ($i ~ "^" flag "=") {
                print substr($i, flag_len + 1)
                exit
            }
            # Check for --flag value format
            if ($i == flag && i < NF) {
                print $(i+1)
                exit
            }
        }
    }'
}

# Extract the -n (short namespace) flag value
# Only matches -n followed by a non-flag argument
# Arguments:
#   $1 - The full command string
# Returns:
#   The namespace value, or empty string if not found
extract_short_namespace() {
    local cmd="$1"
    echo "$cmd" | awk '{
        for(i=1; i<=NF; i++) {
            if ($i == "-n" && i < NF) {
                # Make sure next arg is not another flag (starts with -)
                if ($(i+1) !~ "^-") {
                    print $(i+1)
                    exit
                }
            }
        }
    }'
}

# -----------------------------------------------------------------------------
# Validation Functions
# -----------------------------------------------------------------------------

# Validate that the command specifies an allowed context
# - kubectl must use --context
# - helm must use --kube-context
# Exits with code 1 if validation fails
check_context() {
    local cmd="$1"
    local context=""

    # kubectl uses --context, helm uses --kube-context
    if [[ "$IS_KUBECTL" == "true" ]]; then
        context=$(extract_flag_value "$cmd" "--context")
        if [[ -z "$context" ]]; then
            echo "BLOCKED: kubectl commands must explicitly specify --context"
            echo "Allowed contexts: $ALLOWED_CONTEXTS"
            exit 1
        fi
    fi

    if [[ "$IS_HELM" == "true" ]]; then
        context=$(extract_flag_value "$cmd" "--kube-context")
        if [[ -z "$context" ]]; then
            echo "BLOCKED: helm commands must explicitly specify --kube-context"
            echo "Allowed contexts: $ALLOWED_CONTEXTS"
            exit 1
        fi
    fi

    # Check if context is in allowed list
    local valid=false
    for allowed in $ALLOWED_CONTEXTS; do
        if [[ "$context" == "$allowed" ]]; then
            valid=true
            break
        fi
    done

    if [[ "$valid" != "true" ]]; then
        echo "BLOCKED: Context '$context' is not allowed"
        echo "Allowed contexts: $ALLOWED_CONTEXTS"
        exit 1
    fi
}

# Validate that the command specifies the required namespace
# Accepts -n, --namespace, or --namespace= formats
# Exits with code 1 if validation fails
check_namespace() {
    local cmd="$1"
    local namespace=""

    # Try --namespace first (both = and space-separated)
    namespace=$(extract_flag_value "$cmd" "--namespace")

    # Try -n if --namespace not found
    if [[ -z "$namespace" ]]; then
        namespace=$(extract_short_namespace "$cmd")
    fi

    if [[ -z "$namespace" ]]; then
        echo "BLOCKED: kubectl/helm commands must explicitly specify namespace (-n or --namespace)"
        echo "Required namespace: $REQUIRED_NAMESPACE"
        exit 1
    fi

    if [[ "$namespace" != "$REQUIRED_NAMESPACE" ]]; then
        echo "BLOCKED: Namespace '$namespace' is not allowed"
        echo "Required namespace: $REQUIRED_NAMESPACE"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------

# Run both validations - each will exit 1 if it fails
check_context "$COMMAND"
check_namespace "$COMMAND"

# If we get here, command passed all validations
exit 0

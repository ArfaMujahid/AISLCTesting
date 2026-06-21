#!/usr/bin/env bash
# =============================================================================
# setup-remotes.sh
# -----------------------------------------------------------------------------
# Turns the LOCAL build into the real GitHub submodule architecture in one shot:
#
#   1. Creates the 3 service repos on GitHub and pushes their code.
#   2. Creates the workspace (parent) repo on GitHub.
#   3. Wires each service into the workspace as a git SUBMODULE under services/.
#   4. Commits the .gitmodules + submodule pointers and pushes the workspace.
#
# It is idempotent-ish: repos that already exist are reused, not recreated.
#
# PREREQUISITE: you must be logged in to the GitHub CLI as the target account:
#     gh auth status        # should show you logged in as $GH_USER
#
# Run from anywhere:
#     bash AISLCTesting/scripts/setup-remotes.sh
# =============================================================================
set -euo pipefail

# --- Configuration -----------------------------------------------------------
# Change GH_USER here (and in CLAUDE.md / .cursor rules) if you move to an org.
GH_USER="${GH_USER:-ArfaMujahid}"
VISIBILITY="${VISIBILITY:-public}"          # public | private
PROTO="${PROTO:-https}"                      # https | ssh  (submodule URL scheme)
SERVICES=("user-service" "order-service" "api-gateway")
WORKSPACE_REPO="AISLCTesting"

# Identity used for any commit this script makes (keeps personal repos off your
# work email). Override via env if you like.
GIT_NAME="${GIT_NAME:-Arfa Mujahid}"
GIT_EMAIL="${GIT_EMAIL:-arfamujahid12@gmail.com}"

# --- Resolve paths relative to this script (no matter where it's run from) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"     # the AISLCTesting/ folder
ROOT_DIR="$(cd "$WORKSPACE_DIR/.." && pwd)"       # the parent holding both dirs
STAGING_DIR="$ROOT_DIR/service-staging"           # where the service repos live

# Build a remote URL for a repo name, honoring PROTO.
repo_url() {
  local name="$1"
  if [ "$PROTO" = "ssh" ]; then
    echo "git@github.com:${GH_USER}/${name}.git"
  else
    echo "https://github.com/${GH_USER}/${name}.git"
  fi
}

# --- Preflight: confirm gh is authenticated ----------------------------------
echo "==> Checking GitHub CLI authentication..."
if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: gh is not authenticated. Run:  gh auth login" >&2
  exit 1
fi
WHOAMI="$(gh api user --jq '.login')"
echo "    Logged in as: $WHOAMI"
echo "    Target namespace: $GH_USER   visibility: $VISIBILITY"
if [ "$WHOAMI" != "$GH_USER" ]; then
  echo "    NOTE: you are '$WHOAMI' but creating under '$GH_USER'."
  echo "          That only works if you have push rights there. Set GH_USER=$WHOAMI to use your own."
fi
read -r -p "Proceed and CREATE PUBLIC repos? [y/N] " ok
[ "$ok" = "y" ] || [ "$ok" = "Y" ] || { echo "Aborted."; exit 0; }

# --- Step 1: create + push each service repo ---------------------------------
for svc in "${SERVICES[@]}"; do
  echo "==> Service: $svc"
  if gh repo view "${GH_USER}/${svc}" >/dev/null 2>&1; then
    echo "    Repo already exists — pushing latest."
    git -C "$STAGING_DIR/$svc" remote get-url origin >/dev/null 2>&1 \
      || git -C "$STAGING_DIR/$svc" remote add origin "$(repo_url "$svc")"
    git -C "$STAGING_DIR/$svc" push -u origin main
  else
    # --source pushes the existing local repo as the new GitHub repo's contents.
    gh repo create "${GH_USER}/${svc}" \
      --"$VISIBILITY" \
      --source "$STAGING_DIR/$svc" \
      --remote origin \
      --push
  fi
done

# --- Step 2: prepare the workspace repo locally ------------------------------
echo "==> Preparing workspace repo at $WORKSPACE_DIR"
cd "$WORKSPACE_DIR"
if [ ! -d .git ]; then
  git init -b main -q
  git config user.name  "$GIT_NAME"
  git config user.email "$GIT_EMAIL"
  git add .
  git commit -q -m "chore: workspace scaffold (CLAUDE.md, contracts, aidlc-docs)"
fi

# --- Step 3: create the workspace repo on GitHub (no push yet) ---------------
if ! gh repo view "${GH_USER}/${WORKSPACE_REPO}" >/dev/null 2>&1; then
  # Create the empty remote and set it as origin; we push AFTER adding submodules.
  gh repo create "${GH_USER}/${WORKSPACE_REPO}" --"$VISIBILITY" --source . --remote origin
else
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "$(repo_url "$WORKSPACE_REPO")"
fi

# --- Step 4: add each service as a submodule under services/ -----------------
for svc in "${SERVICES[@]}"; do
  if [ -f ".gitmodules" ] && grep -q "services/$svc" .gitmodules; then
    echo "==> Submodule services/$svc already wired — skipping."
    continue
  fi
  echo "==> Adding submodule services/$svc -> $(repo_url "$svc")"
  # Remove any empty placeholder dir so submodule add has a clean target.
  rmdir "services/$svc" 2>/dev/null || true
  git submodule add "$(repo_url "$svc")" "services/$svc"
done

# --- Step 5: commit pointers + push the workspace ----------------------------
git add .gitmodules services
git commit -q -m "feat: add user-service, order-service, api-gateway as submodules"
git push -u origin main

echo ""
echo "DONE. Repos:"
for r in "$WORKSPACE_REPO" "${SERVICES[@]}"; do
  echo "  https://github.com/${GH_USER}/${r}"
done
echo ""
echo "Clone elsewhere with:  git clone --recurse-submodules $(repo_url "$WORKSPACE_REPO")"

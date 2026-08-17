#!/usr/bin/env bash
# =============================================================================
# FitFusion — local toolchain preflight
#
# Checks every dependency the V1 backend actually needs, and explains how to
# fix whatever is missing. Read-only: installs nothing, changes nothing.
#
#   bash preflight.sh
# =============================================================================

set -uo pipefail

# Minimums that matter for THIS project
RUBY_MIN="3.2.0"       # Rails 8 hard requirement
RUBY_WANT="3.3.0"      # what we target
PG_MIN="14"            # native enums, check constraints
PG_WANT="16"           # what the schema was verified against

if [ -t 1 ]; then
  R=$'\033[0m'; B=$'\033[1m'; DIM=$'\033[2m'
  GRN=$'\033[32m'; YEL=$'\033[33m'; RED=$'\033[31m'; CYN=$'\033[36m'
else
  R=""; B=""; DIM=""; GRN=""; YEL=""; RED=""; CYN=""
fi

PASS=0; WARN=0; FAIL=0
FIXES=()

ok()   { printf "  ${GRN}✓${R} %-26s ${DIM}%s${R}\n" "$1" "${2:-}"; PASS=$((PASS+1)); }
warn() { printf "  ${YEL}!${R} %-26s %s\n" "$1" "${2:-}"; WARN=$((WARN+1)); [ -n "${3:-}" ] && FIXES+=("${YEL}!${R} $3"); }
bad()  { printf "  ${RED}✗${R} %-26s %s\n" "$1" "${2:-}"; FAIL=$((FAIL+1)); [ -n "${3:-}" ] && FIXES+=("${RED}✗${R} $3"); }
sect() { printf "\n${B}%s${R}\n" "$1"; }

# version_ge A B  -> true if A >= B
version_ge() {
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]
}

printf "${B}FitFusion — toolchain preflight${R}\n"
printf "${DIM}%s${R}\n" "$(date '+%Y-%m-%d %H:%M')"

# ---------------------------------------------------------------- system
sect "System"

OS="$(uname -s)"
ARCH="$(uname -m)"
if [ "$OS" = "Darwin" ]; then
  ok "macOS" "$(sw_vers -productVersion 2>/dev/null) · $ARCH"
else
  warn "OS" "$OS $ARCH (script tuned for macOS)"
fi

if xcode-select -p >/dev/null 2>&1; then
  ok "Xcode CLT" "$(xcode-select -p)"
else
  bad "Xcode CLT" "missing — native gems (pg, nokogiri) won't build" \
      "Install command line tools:  xcode-select --install"
fi

if command -v brew >/dev/null 2>&1; then
  ok "Homebrew" "$(brew --version 2>/dev/null | head -1)"
else
  warn "Homebrew" "not found" \
       "Install Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
fi

if command -v git >/dev/null 2>&1; then
  ok "git" "$(git --version | awk '{print $3}')"
else
  bad "git" "missing" "brew install git"
fi

# ---------------------------------------------------------------- ruby
sect "Ruby"

MGR="system"
command -v rbenv  >/dev/null 2>&1 && MGR="rbenv"
command -v asdf   >/dev/null 2>&1 && MGR="asdf"
command -v rvm    >/dev/null 2>&1 && MGR="rvm"
command -v mise   >/dev/null 2>&1 && MGR="mise"
if [ "$MGR" = "system" ]; then
  warn "version manager" "none detected" \
       "A manager avoids sudo-installing gems into system Ruby:  brew install rbenv"
else
  ok "version manager" "$MGR"
fi

if command -v ruby >/dev/null 2>&1; then
  RUBY_V="$(ruby -e 'print RUBY_VERSION' 2>/dev/null)"
  RUBY_WHERE="$(command -v ruby)"
  if [ "$RUBY_WHERE" = "/usr/bin/ruby" ]; then
    bad "ruby" "$RUBY_V (system Ruby at /usr/bin/ruby)" \
        "macOS system Ruby is frozen and not writable. Install your own:  rbenv install ${RUBY_WANT} && rbenv global ${RUBY_WANT}"
  elif version_ge "$RUBY_V" "$RUBY_WANT"; then
    ok "ruby" "$RUBY_V  ($RUBY_WHERE)"
  elif version_ge "$RUBY_V" "$RUBY_MIN"; then
    warn "ruby" "$RUBY_V — runs Rails 8, but ${RUBY_WANT}+ recommended" \
         "Upgrade Ruby:  rbenv install ${RUBY_WANT} && rbenv global ${RUBY_WANT}"
  else
    bad "ruby" "$RUBY_V — Rails 8 requires >= ${RUBY_MIN}" \
        "Upgrade Ruby:  rbenv install ${RUBY_WANT} && rbenv global ${RUBY_WANT}"
  fi
else
  bad "ruby" "not found" "brew install rbenv && rbenv install ${RUBY_WANT}"
fi

if command -v bundle >/dev/null 2>&1; then
  # "Bundler version 2.5.22" on some installs, bare "2.5.22" on others
  BUNDLER_V="$(bundle --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
  ok "bundler" "${BUNDLER_V:-installed}"
else
  bad "bundler" "not found" "gem install bundler"
fi

if command -v rails >/dev/null 2>&1; then
  RAILS_V="$(rails --version 2>/dev/null | awk '{print $2}')"
  if version_ge "${RAILS_V:-0}" "8.0.0"; then
    ok "rails" "$RAILS_V"
  elif version_ge "${RAILS_V:-0}" "7.1.0"; then
    warn "rails" "$RAILS_V — spec targets 8.x" "gem install rails"
  else
    bad "rails" "$RAILS_V — too old for this schema" "gem install rails"
  fi
else
  bad "rails" "not found" "gem install rails"
fi

# ---------------------------------------------------------------- postgres
sect "PostgreSQL"

PG_OK=0
if command -v psql >/dev/null 2>&1; then
  PGC_V="$(psql --version 2>/dev/null | awk '{print $3}' | cut -d. -f1)"
  if version_ge "${PGC_V:-0}" "$PG_WANT"; then
    ok "psql (client)" "$(psql --version | awk '{print $3}')"
  elif version_ge "${PGC_V:-0}" "$PG_MIN"; then
    warn "psql (client)" "$(psql --version | awk '{print $3}') — schema verified on ${PG_WANT}" \
         "brew install postgresql@${PG_WANT}"
  else
    bad "psql (client)" "$(psql --version | awk '{print $3}') — too old" \
        "brew install postgresql@${PG_WANT}"
  fi
else
  bad "psql (client)" "not found" \
      "brew install postgresql@${PG_WANT} && brew services start postgresql@${PG_WANT}"
fi

if command -v pg_config >/dev/null 2>&1; then
  ok "libpq / pg_config" "$(pg_config --version 2>/dev/null)"
else
  bad "libpq / pg_config" "missing — the 'pg' gem cannot compile" \
      "brew install libpq && brew link --force libpq"
fi

# Is a server actually reachable?
PGUSER_TRY="${PGUSER:-$(whoami)}"
if command -v psql >/dev/null 2>&1; then
  if psql -d postgres -tAc 'SELECT 1' >/dev/null 2>&1; then
    SRV_V="$(psql -d postgres -tAc 'SHOW server_version' 2>/dev/null)"
    ok "server reachable" "v${SRV_V} as '${PGUSER_TRY}'"
    PG_OK=1
  else
    bad "server reachable" "cannot connect to 'postgres' db as '${PGUSER_TRY}'" \
        "Start it:  brew services start postgresql@${PG_WANT}   (then re-run this script)"
  fi
fi

# The four extensions this schema depends on
if [ "$PG_OK" = "1" ]; then
  MISSING=""
  for EXT in pgcrypto citext unaccent pg_trgm; do
    FOUND="$(psql -d postgres -tAc "SELECT 1 FROM pg_available_extensions WHERE name='${EXT}'" 2>/dev/null)"
    [ "$FOUND" = "1" ] || MISSING="${MISSING} ${EXT}"
  done
  if [ -z "$MISSING" ]; then
    ok "extensions" "pgcrypto, citext, unaccent, pg_trgm all available"
  else
    bad "extensions" "unavailable:${MISSING}" \
        "Your Postgres build lacks contrib modules. Reinstall:  brew install postgresql@${PG_WANT}"
  fi

  SUPER="$(psql -d postgres -tAc "SELECT usesuper FROM pg_user WHERE usename=current_user" 2>/dev/null)"
  if [ "$SUPER" = "t" ]; then
    ok "role privileges" "'${PGUSER_TRY}' is superuser (can CREATE EXTENSION)"
  else
    warn "role privileges" "'${PGUSER_TRY}' is not superuser" \
         "CREATE EXTENSION needs superuser:  psql -d postgres -c \"ALTER ROLE ${PGUSER_TRY} SUPERUSER;\""
  fi
fi

# ---------------------------------------------------------------- extras
sect "Supporting tools"

if command -v node >/dev/null 2>&1; then
  ok "node" "$(node -v)  ${DIM}(optional — tailwindcss-rails ships a standalone binary)${R}"
else
  warn "node" "not found (optional)" "Only needed if you add JS bundling later:  brew install node"
fi

if command -v redis-server >/dev/null 2>&1; then
  ok "redis" "$(redis-server --version | awk '{print $3}' | cut -d= -f2)  ${DIM}(optional until background jobs)${R}"
else
  warn "redis" "not found (optional)" "Not needed for V1. Later, for Sidekiq:  brew install redis"
fi

# ---------------------------------------------------------------- summary
printf "\n${B}Summary${R}\n"
printf "  ${GRN}%d passed${R}   ${YEL}%d warnings${R}   ${RED}%d blocking${R}\n" "$PASS" "$WARN" "$FAIL"

if [ ${#FIXES[@]} -gt 0 ]; then
  printf "\n${B}To fix${R}\n"
  for f in "${FIXES[@]}"; do printf "  %s\n" "$f"; done
fi

printf "\n"
if [ "$FAIL" -eq 0 ]; then
  printf "${GRN}${B}Ready.${R} Nothing blocking — you can run the generator.\n"
  printf "${DIM}  cd ~/dev/fitness_app && rails new backend --database=postgresql --css=tailwind --skip-test${R}\n\n"
  exit 0
else
  printf "${RED}${B}Blocked.${R} Resolve the ✗ items above, then re-run this script.\n\n"
  exit 1
fi

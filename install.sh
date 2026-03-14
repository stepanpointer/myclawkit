#!/usr/bin/env bash
set -euo pipefail

# myclawkit — Initial configuration for OpenClaw
# https://docs.openclaw.ai

BOLD="\033[1m"; GREEN="\033[0;32m"; YELLOW="\033[0;33m"; RED="\033[0;31m"; RESET="\033[0m"
log_info()   { echo -e "${GREEN}✓${RESET} $1"; }
log_warn()   { echo -e "${YELLOW}⚠${RESET} $1"; }
log_error()  { echo -e "${RED}✗${RESET} $1"; }
log_header() { echo -e "\n${BOLD}$1${RESET}"; }

# ─── State ─────────────────────────────────────────────────────────────────────
PROVIDER=""
MODEL=""
declare -a CHANNELS=()
TELEGRAM_TOKEN=""
declare -a TELEGRAM_ALLOW=()
DISCORD_TOKEN=""
SLACK_BOT_TOKEN=""
SLACK_APP_TOKEN=""
TIMEZONE=""
WORKSPACE=""
FORCE=false

INTERACTIVE=false
[ -t 0 ] && INTERACTIVE=true

# ─── Usage ─────────────────────────────────────────────────────────────────────
usage() {
  cat <<'EOF'
Usage: ./install.sh [OPTIONS]

Options:
  --provider PROVIDER        AI provider (default: anthropic)
                             anthropic | openai | openrouter | mistral | ollama | bedrock | ...
  --model MODEL              Primary model. Without provider prefix, combined with --provider.
                             Examples: claude-opus-4-6  |  anthropic/claude-opus-4-6
  --channel CHANNEL          Enable a messaging channel (repeatable)
                             telegram | discord | slack | whatsapp | signal
  --telegram-token TOKEN     Telegram bot token
  --telegram-allow ID        Allowed Telegram user ID (repeatable)
  --discord-token TOKEN      Discord bot token
  --slack-bot-token TOKEN    Slack bot token (xoxb-...)
  --slack-app-token TOKEN    Slack app token (xapp-..., socket mode)
  --timezone TZ              Timezone (default: UTC), e.g. Europe/Moscow
  --workspace PATH           Workspace directory (default: ~/myclawkit-workspace)
  --force                    Overwrite existing config if present
  -h, --help                 Show this help

Examples:
  # Minimal – defaults only
  ./install.sh

  # Provider + model + timezone
  ./install.sh --provider anthropic --model claude-opus-4-6 --timezone Europe/Moscow

  # With Telegram channel and allowlist
  ./install.sh --channel telegram \
               --telegram-token "123456:ABC" \
               --telegram-allow "987654321"

  # Multiple channels
  ./install.sh --provider openai --model gpt-4o \
               --channel telegram --telegram-token "TOKEN" \
               --channel discord --discord-token "BOT_TOKEN"
EOF
}

# ─── Argument parsing ──────────────────────────────────────────────────────────
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --provider)        PROVIDER="$2";          shift 2 ;;
      --model)           MODEL="$2";             shift 2 ;;
      --channel)         CHANNELS+=("$2");        shift 2 ;;
      --telegram-token)  TELEGRAM_TOKEN="$2";     shift 2 ;;
      --telegram-allow)  TELEGRAM_ALLOW+=("$2");  shift 2 ;;
      --discord-token)   DISCORD_TOKEN="$2";      shift 2 ;;
      --slack-bot-token) SLACK_BOT_TOKEN="$2";    shift 2 ;;
      --slack-app-token) SLACK_APP_TOKEN="$2";    shift 2 ;;
      --timezone)        TIMEZONE="$2";           shift 2 ;;
      --workspace)       WORKSPACE="$2";          shift 2 ;;
      --force)           FORCE=true;              shift ;;
      -h|--help)         usage; exit 0 ;;
      *) log_error "Unknown option: $1"; echo; usage; exit 1 ;;
    esac
  done

  PROVIDER="${PROVIDER:-anthropic}"
  TIMEZONE="${TIMEZONE:-UTC}"
  WORKSPACE="${WORKSPACE:-$HOME/myclawkit-workspace}"

  if [[ -z "$MODEL" ]]; then
    case "$PROVIDER" in
      anthropic)  MODEL="anthropic/claude-opus-4-6" ;;
      openai)     MODEL="openai/gpt-4o" ;;
      openrouter) MODEL="openrouter/anthropic/claude-opus-4-6" ;;
      mistral)    MODEL="mistral/mistral-large-latest" ;;
      ollama)     MODEL="ollama/llama3" ;;
      bedrock)    MODEL="bedrock/anthropic.claude-opus-4-6-v2:0" ;;
      *)          MODEL="${PROVIDER}/default" ;;
    esac
  elif [[ "$MODEL" != */* ]]; then
    MODEL="${PROVIDER}/${MODEL}"
  fi
}

# ─── Requirements ──────────────────────────────────────────────────────────────
check_requirements() {
  log_header "Проверка зависимостей"

  if ! command -v git &>/dev/null; then
    log_error "Git не установлен"; exit 1
  fi
  log_info "Git: $(git --version | cut -d' ' -f3)"

  if command -v openclaw &>/dev/null; then
    log_info "OpenClaw: $(openclaw --version 2>/dev/null | head -1 || echo 'установлен')"
  else
    log_warn "openclaw не найден в PATH — убедитесь, что OpenClaw установлен"
  fi
}

# ─── Config ────────────────────────────────────────────────────────────────────
write_channel() {
  local ch="$1"
  local trailing_comma="$2"  # "," or ""

  case "$ch" in
    telegram)
      local allow_arr="[]"
      if [ ${#TELEGRAM_ALLOW[@]} -gt 0 ]; then
        local ids=""
        for id in "${TELEGRAM_ALLOW[@]}"; do ids+="\"$id\","; done
        allow_arr="[${ids%,}]"
      fi
      local dm_policy="open"
      [ ${#TELEGRAM_ALLOW[@]} -gt 0 ] && dm_policy="allowlist"
      cat <<EOF
    "telegram": {
      "enabled": true,
      "botToken": "$TELEGRAM_TOKEN",
      "dmPolicy": "$dm_policy",
      "allowFrom": $allow_arr
    }${trailing_comma}
EOF
      ;;
    discord)
      cat <<EOF
    "discord": {
      "enabled": true,
      "token": "$DISCORD_TOKEN",
      "groupPolicy": "allowlist"
    }${trailing_comma}
EOF
      ;;
    slack)
      cat <<EOF
    "slack": {
      "enabled": true,
      "mode": "socket",
      "botToken": "$SLACK_BOT_TOKEN",
      "appToken": "$SLACK_APP_TOKEN"
    }${trailing_comma}
EOF
      ;;
    whatsapp)
      cat <<EOF
    "whatsapp": {
      "enabled": true
    }${trailing_comma}
EOF
      ;;
    signal)
      cat <<EOF
    "signal": {
      "enabled": true
    }${trailing_comma}
EOF
      ;;
    *)
      log_warn "Неизвестный канал: $ch (пропускаем)"
      ;;
  esac
}

setup_config() {
  log_header "Настройка конфигурации OpenClaw"

  local config_file="$HOME/.openclaw/openclaw.json"
  local workspace="$WORKSPACE"
  mkdir -p "$(dirname "$config_file")"

  if [ -f "$config_file" ] && ! $FORCE; then
    log_warn "Конфиг уже существует: $config_file (пропускаем, используйте --force для перезаписи)"
    return
  fi

  local n=${#CHANNELS[@]}

  {
    cat <<EOF
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "$MODEL"
      },
      "workspace": "$workspace",
      "timezone": "$TIMEZONE"
    }
  },
  "channels": {
EOF

    for ((i=0; i<n; i++)); do
      local comma=""
      ((i < n-1)) && comma=","
      write_channel "${CHANNELS[$i]}" "$comma"
    done

    cat <<'EOF'
  }
}
EOF
  } > "$config_file"

  log_info "Конфиг создан: $config_file"
  log_info "Модель: $MODEL | Timezone: $TIMEZONE"
  if [ "$n" -gt 0 ]; then
    log_info "Каналы: ${CHANNELS[*]}"
  else
    log_info "Каналы: не настроены — добавьте в $config_file вручную"
    log_info "Документация: https://docs.openclaw.ai/channels/index.md"
  fi
}

# ─── Soul / workspace files ────────────────────────────────────────────────────
import_soul() {
  log_header "Импорт конфигурации агента"

  local workspace="$WORKSPACE"
  mkdir -p "$workspace"

  local copied=0
  for f in SOUL.md AGENTS.md IDENTITY.md USER.md BOOTSTRAP.md; do
    if [ -f "$(pwd)/$f" ]; then
      if [ -f "$workspace/$f" ]; then
        log_warn "$f уже существует в $workspace (пропускаем)"
      else
        cp "$(pwd)/$f" "$workspace/"
        log_info "$f → $workspace/"
        copied=$((copied + 1))
      fi
    fi
  done

  # docs/
  if [ -d "$(pwd)/docs" ]; then
    mkdir -p "$workspace/docs"
    for f in "$(pwd)"/docs/*.md; do
      [ -f "$f" ] || continue
      local fname
      fname=$(basename "$f")
      if [ -f "$workspace/docs/$fname" ]; then
        log_warn "docs/$fname уже существует (пропускаем)"
      else
        cp "$f" "$workspace/docs/"
        log_info "docs/$fname → $workspace/docs/"
        copied=$((copied + 1))
      fi
    done
  fi

  if [ "$copied" -eq 0 ] && [ ! -f "$workspace/SOUL.md" ]; then
    log_warn "SOUL.md не найден — агент запустится без персонализации"
  fi
}

# ─── Memory import (interactive only) ─────────────────────────────────────────
import_memory() {
  if ! $INTERACTIVE; then
    return
  fi

  log_header "Импорт памяти (опционально)"

  read -p "Путь к .md файлам памяти (Enter для пропуска): " memory_path

  if [ -z "$memory_path" ]; then
    log_info "Пропускаем — память будет накапливаться автоматически"
    return
  fi

  memory_path="${memory_path/#\~/$HOME}"

  if [ ! -d "$memory_path" ] && [ ! -f "$memory_path" ]; then
    log_warn "Путь не найден: $memory_path"
    return
  fi

  local memory_dir="$HOME/.openclaw/memory"
  mkdir -p "$memory_dir"

  local count=0
  if [ -d "$memory_path" ]; then
    for f in "$memory_path"/*.md; do
      [ -f "$f" ] || continue
      cp "$f" "$memory_dir/imported-$(basename "$f")"
      count=$((count + 1))
    done
  elif [ -f "$memory_path" ]; then
    cp "$memory_path" "$memory_dir/imported-$(basename "$memory_path")"
    count=1
  fi

  if [ "$count" -gt 0 ]; then
    log_info "Скопировано $count файлов памяти в $memory_dir"
  else
    log_warn "Файлы .md не найдены в $memory_path"
  fi
}

# ─── Skills ────────────────────────────────────────────────────────────────────
install_skills() {
  log_header "Установка skills"

  local skills_src="$(pwd)/skills"
  local skills_dst="$HOME/.openclaw/skills"

  if [ ! -d "$skills_src" ]; then
    log_warn "Директория skills не найдена"
    return
  fi

  local available
  available=$(find "$skills_src" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  echo "Доступно skills: $available"
  echo ""
  ls -1 "$skills_src" | while read -r s; do echo "  - $s"; done
  echo ""

  local do_install=false
  if $INTERACTIVE; then
    read -p "Установить все $available skills? (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] && do_install=true
  else
    do_install=true
    log_info "Не-интерактивный режим: устанавливаем все skills"
  fi

  if ! $do_install; then
    log_info "Пропускаем. Позже: cp -r skills/* ~/.openclaw/skills/"
    return
  fi

  mkdir -p "$skills_dst"
  local count=0
  for skill_dir in "$skills_src"/*/; do
    local skill_name
    skill_name=$(basename "$skill_dir")
    if [ -d "$skills_dst/$skill_name" ]; then
      log_warn "Skill '$skill_name' уже существует, пропускаем"
    else
      cp -r "$skill_dir" "$skills_dst/"
      count=$((count + 1))
    fi
  done

  log_info "Установлено $count skills в $skills_dst"
}

# ─── Summary ───────────────────────────────────────────────────────────────────
print_summary() {
  log_header "Готово ⚡"
  echo ""
  echo "Что дальше:"
  echo ""
  echo "1. Заполните профиль:"
  echo "   $WORKSPACE/USER.md      ← кто вы, чем занимаетесь"
  echo "   $WORKSPACE/IDENTITY.md  ← имя агента, timezone"
  echo ""
  echo "2. Проверьте и дополните конфиг:"
  echo "   ~/.openclaw/openclaw.json"
  echo "   Справка: https://docs.openclaw.ai/gateway/configuration-reference.md"
  echo ""
  echo "3. Запустите OpenClaw:"
  echo "   openclaw start"
  echo ""
  echo "4. Проверьте состояние:"
  echo "   openclaw status"
  echo "   openclaw doctor"
  echo ""
}

# ─── Entry point ───────────────────────────────────────────────────────────────
main() {
  echo -e "${BOLD}myclawkit ⚡${RESET}"
  echo "Initial configuration for OpenClaw"
  echo ""

  parse_args "$@"
  check_requirements
  setup_config
  import_soul
  import_memory
  install_skills
  print_summary
}

main "$@"

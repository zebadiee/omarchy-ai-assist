#!/usr/bin/env bash
# LM Studio / OpenAI-compatible local CLI for Omarchy OS
# Works with any server exposing /v1/chat/completions or /v1/embeddings

set -euo pipefail

# Default to LM Studio's actual port on this system
BASE_URL="${LMSTUDIO_BASE_URL:-http://127.0.0.1:41343/v1}"
API_KEY="${LMSTUDIO_API_KEY:-lm-studio}"
MODEL_DEFAULT="${LMSTUDIO_MODEL:-lmstudio-local}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1" >&2; exit 1; }; }

need curl
need jq

usage() {
  cat <<'EOF'
🤖 LM Studio CLI — Omarchy AI Assist Interface

Talk to local OpenAI-compatible servers (LM Studio, Ollama, llama.cpp, etc.)

USAGE:
  lms_cli.sh ping
  lms_cli.sh chat   [-m MODEL] [-s SYSTEM_PROMPT] "user message"
  lms_cli.sh embed  [-m MODEL] "text to embed"
  lms_cli.sh models
  lms_cli.sh raw    <method> <endpoint> [json payload via stdin]

ENVIRONMENT:
  LMSTUDIO_BASE_URL (default: http://127.0.0.1:41343/v1)
  LMSTUDIO_API_KEY  (default: lm-studio)
  LMSTUDIO_MODEL    (default: lmstudio-local)

OMARCHY INTEGRATION EXAMPLES:
  lms_cli.sh ping                          # Check if LM Studio is running
  lms_cli.sh models                        # List available models
  lms_cli.sh chat -s "You are an Omarchy OS expert" "How do I customize my desktop?"
  lms_cli.sh chat -m "mistral" "Generate Go code for system monitoring"
  lms_cli.sh embed "Vectorize this Omarchy documentation text"

AI SUBAGENT WORKFLOW:
  export AI_PROVIDER=lmstudio
  #pln "Plan the architecture using LM Studio"
  #imp "Implement this component with LM Studio code generation"
  #knw "Extract knowledge patterns with LM Studio analysis"
EOF
}

auth_hdr=(-H "authorization: Bearer ${API_KEY}")
json_hdr=(-H "content-type: application/json")

get()  { curl -fsS "${auth_hdr[@]}" "$@" 2>/dev/null || curl -fsS "$@"; }
post() { curl -fsS "${auth_hdr[@]}" "${json_hdr[@]}" -d @- "$@" 2>/dev/null || curl -fsS "${json_hdr[@]}" -d @- "$@"; }

cmd="${1:-}"; shift || true

case "$cmd" in
  ping)
    echo "🔍 Pinging LM Studio at ${BASE_URL}..."
    # Try to get models list first (lighter than chat completion)
    if get "${BASE_URL}/models" >/dev/null 2>&1; then
      echo "✅ LM Studio is running and responsive"
      echo "📡 Server: ${BASE_URL}"
    else
      echo "❌ Ping failed. Is LM Studio running at ${BASE_URL}?"
      echo "💡 Try: Start LM Studio and enable 'OpenAI Compatible Server'"
      exit 2
    fi
    ;;
  models)
    echo "📋 Available Models:"
    get "${BASE_URL}/models" | jq -r '.data[]? | "  • \(.id) (\(.object//.type//unknown))"' 2>/dev/null || {
      echo "❌ Could not fetch models list"
      echo "💡 Using default model: ${MODEL_DEFAULT}"
    }
    ;;
  chat)
    model="$MODEL_DEFAULT"
    system=""
    stream="false"
    # Parse flags
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -m|--model) model="$2"; shift 2;;
        -s|--system) system="$2"; shift 2;;
        --stream) stream="true"; shift;;
        -h|--help) usage; exit 0;;
        *) break;;
      esac
    done
    user_msg="${*:-}"
    [[ -n "$user_msg" ]] || { echo "❌ Provide a user message."; usage; exit 1; }

    echo "🤖 Querying LM Studio (${model})..."
    if [[ -n "$system" ]]; then
      payload=$(jq -n --arg m "$model" --arg sys "$system" --arg usr "$user_msg" \
        --arg stream "$stream" \
        '{model:$m, messages:[{role:"system",content:$sys},{role:"user",content:$usr}], stream:($stream|test("true"))}')
    else
      payload=$(jq -n --arg m "$model" --arg usr "$user_msg" \
        --arg stream "$stream" \
        '{model:$m, messages:[{role:"user",content:$usr}], stream:($stream|test("true"))}')
    fi

    echo "$payload" | post "${BASE_URL}/chat/completions" | jq -r '.choices[0].message.content' || {
      echo "❌ Chat request failed"
      echo "💡 Check model name and server status"
      echo "🔍 Try: lms_cli.sh models"
    }
    ;;
  embed|embeddings)
    model="$MODEL_DEFAULT"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -m|--model) model="$2"; shift 2;;
        -h|--help) usage; exit 0;;
        *) break;;
      esac
    done
    text="${*:-}"
    [[ -n "$text" ]] || { echo "❌ Provide text to embed."; usage; exit 1; }

    echo "🔢 Generating embeddings..."
    jq -n --arg m "$model" --arg t "$text" \
      '{model:$m, input:$t}' \
    | post "${BASE_URL}/embeddings" | jq -r '.data[0].embedding | @json' || {
      echo "❌ Embedding request failed"
      echo "💡 Check if embeddings are supported by the current model"
    }
    ;;
  raw)
    method="${1:-}"; shift || true
    endpoint="${1:-}"; shift || true
    [[ -n "$method" && -n "$endpoint" ]] || { usage; exit 1; }
    url="${BASE_URL%/}/${endpoint#/}"
    echo "🔧 Raw ${method} ${url}"
    case "$method" in
      GET|get)  get "$url";;
      POST|post) post "$url";;
      *) echo "❌ Unsupported method: $method" >&2; usage; exit 1;;
    esac
    ;;
  ""|-h|--help) usage;;
  *)
    echo "❌ Unknown command: $cmd"
    echo ""
    usage
    exit 1
    ;;
esac
# --- Go build + vet gate ---
if [ -f go.mod ]; then
  echo "go build + vet..." >&2
  if ! go build ./... 2>&1; then
    echo "차단: go build 실패." >&2
    exit 2
  fi
  if ! go vet ./... 2>&1; then
    echo "차단: go vet 실패." >&2
    exit 2
  fi
  # golangci-lint (있으면)
  if command -v golangci-lint >/dev/null 2>&1; then
    if ! golangci-lint run --fast ./... 2>&1; then
      echo "차단: golangci-lint 실패." >&2
      exit 2
    fi
  fi
fi

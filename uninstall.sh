#!/usr/bin/env bash

# ==============================================================================
# Script de Remoção: Restore Havit Fuxi-H3
# ==============================================================================

set -e

RULE_FILE="/etc/udev/rules.d/99-havit-fuxi-fix.rules"

echo "==> Removendo fix do Havit Fuxi-H3..."

if [ "$EUID" -ne 0 ]; then
  echo "[ERRO] Este script precisa ser executado como root (sudo)." >&2
  exit 1
fi

if [ -f "$RULE_FILE" ]; then
  rm -f "$RULE_FILE"
  echo "==> Arquivo $RULE_FILE removido."
  udevadm control --reload-rules
  udevadm trigger
  echo "==> Regras do udev atualizadas."
else
  echo "==> Nenhuma instalação prévia encontrada em $RULE_FILE."
fi

echo "==> Remoção concluída."

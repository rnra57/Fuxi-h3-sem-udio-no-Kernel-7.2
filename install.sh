#!/usr/bin/env bash

# ==============================================================================
# Script de Instalação: Fix para Havit Fuxi-H3 (Regressão Áudio USB Kernel 7.2+)
# ==============================================================================

set -e

RULE_FILE="/etc/udev/rules.d/99-havit-fuxi-fix.rules"

echo "==> Iniciando instalação do fix para Havit Fuxi-H3..."

# Verificação de privilégios de root
if [ "$EUID" -ne 0 ]; then
  echo "[ERRO] Este script precisa ser executado como root (sudo)." >&2
  exit 1
fi

# 1. Criar regra do Udev
echo "==> Criando regra em $RULE_FILE..."
cat << 'EOF' > "$RULE_FILE"
# Fix de volume para Havit Fuxi-H3 (040b:0897) - Regressão Kernel 7.2
ACTION=="add", SUBSYSTEM=="sound", ATTRS{idVendor}=="040b", ATTRS{idProduct}=="0897", RUN+="/usr/bin/amixer -c FuxiH3 cset numid=10 100"
EOF

# 2. Recarregar regras do udev
echo "==> Recarregando regras do udev..."
udevadm control --reload-rules
udevadm trigger

# 3. Aplicar a correção imediatamente se o dispositivo estiver conectado
if aplay -l | grep -q -i "FuxiH3"; then
  echo "==> Dispositivo Havit Fuxi-H3 detectado. Aplicando ajuste de mixer..."
  amixer -c FuxiH3 cset numid=10 100 >/dev/null 2>&1 || true
  alsactl store >/dev/null 2>&1 || true
  echo "==> Correção aplicada com sucesso!"
else
  echo "==> Dongle do headset não detectado no momento. A regra será aplicada automaticamente ao conectá-lo."
fi

echo "==> Concluído!"

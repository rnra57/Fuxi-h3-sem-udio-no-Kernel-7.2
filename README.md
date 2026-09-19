# Havit Fuxi-H3 USB Audio Fix (Kernel 7.2+)

![Linux Kernel](https://img.shields.io/badge/Linux-Kernel%207.2%2B-blue?logo=linux)
![Fedora](https://img.shields.io/badge/Fedora-44%2B-blue?logo=fedora)
![License](https://img.shields.io/badge/License-MIT-green)

Workaround e correção automatizada para a regressão de áudio no headset sem fio **Havit Fuxi-H3** (Dongle USB 2.4GHz) no Linux Kernel **7.2.x** ou superior.

---

## 📌 Descrição do Problema

A partir do **Kernel Linux 7.2**, o subsistema `snd-usb-audio` alterou a rotina de parsing de *Feature Units* de dispositivos USB. Essa mudança cria um segundo controle de volume PCM zerado (`index=1` / `numid=10`) no hardware do dongle **Weltrend / XiiSound (ID USB `040b:0897`)**, travando a saída de áudio física (o microfone continua funcionando, mas a reprodução fica completamente muda).

Este repositório fornece um script de automação e uma regra `udev` que força a reabertura do canal de hardware `numid=10` no nível do ALSA sempre que o dongle é conectado.

---

## 🛠️ Requisitos

* Linux Kernel 7.2+
* ALSA Utilities (`amixer`, `aplay`, `alsactl`)
* Permissões de superusuário (`sudo`)

---

## 🚀 Instalação Rápida

Clone o repositório e execute o script de instalação:

```bash
git clone [https://github.com/seu-usuario/havit-fuxi-h3-fix.git](https://github.com/seu-usuario/havit-fuxi-h3-fix.git)
cd havit-fuxi-h3-fix
chmod +x install.sh uninstall.sh
sudo ./install.sh
```

O script irá:

    Criar a regra persistente no Udev (/etc/udev/rules.d/99-havit-fuxi-fix.rules).

    Recarregar o subsistema udevadm.

    Aplicar imediatamente o ajuste no mixer ALSA se o headset estiver conectado.

⚙️ Teste Manual / Diagnóstico

Se preferir testar a correção manualmente no terminal antes de instalar:
Bash

# Verificar se o cartão ALSA foi identificado como FuxiH3
aplay -l | grep -i "Fuxi"

# Aplicar a correção do registro de hardware diretamente
amixer -c FuxiH3 cset numid=10 100

# Testar a saída de áudio
speaker-test -D plughw:FuxiH3,0 -c 2 -t wav

🗑️ Desinstalação

Para remover a regra udev e restaurar o estado original do sistema:
Bash

sudo ./uninstall.sh

📄 Licença

Este projeto está licenciado sob a licença MIT.

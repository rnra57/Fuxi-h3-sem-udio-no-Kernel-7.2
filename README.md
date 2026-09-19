# Documentação Técnica: Regressão de Áudio USB no Kernel Linux 7.2 (Havit Fuxi-H3)

## 1. Descrição do Problema

Após a atualização do kernel do Linux para a versão **7.2.x**, o headset sem fio **Havit Fuxi-H3** (conectado via dongle USB 2.4GHz) deixou de emitir áudio de saída, mantendo apenas a funcionalidade do microfone (captura de áudio) operacional.

### Especificações do Dispositivo

- **Modelo:** Havit Fuxi-H3 Wireless

- **ID USB (Dongle):** `040b:0897` Weltrend Semiconductor / XiiSound Technology Corporation

## 2. Diagnóstico e Causa Raiz

### Comparativo de Logs do Kernel (`dmesg` / `journalctl`)

- **Kernel 7.1.x (Operacional):**

  Plaintext

```
usb 1-4.1.2: [5] FU [PCM Playback Volume] ch = 1, val = 0/100/1
usb 1-4.1.2: 5:0: sticky mixer values (0/100/1 => 80), disabling
```

- **Kernel 7.2.x (Falha):**

  Plaintext

```
usb 1-4.1.2: 5:0: broken mixer GET_CUR (0/100/1 => 80)
usb 1-4.1.2: [5] FU [PCM Playback Volume] ch = 2, val = 0/100/1
usb 1-4.1.2: [5] FU [PCM Playback Volume] ch = 1, val = 0/100/1
```

### Causa Raiz

A partir do Kernel 7.2, o subsistema de áudio USB (`snd-usb-audio`) alterou a rotina de parsing de *Feature Units* (FU) de firmware para áudio USB. Ao tentar interpretar o controle de volume como estéreo (`ch = 2`) e reatribuir para mono (`ch = 1`), o ALSA gerou **duas instâncias de controle de volume para a mesma saída PCM**:

1. `index=0` (`numid=9`): Definido com volume padrão em 100%.

2. `index=1` (`numid=10`): Inicializado pelo kernel com o valor zerado (`values=0`).

Como o DAC do hardware do dongle XiiSound exige que ambos os registros virtuais de controle de volume estejam ativos para liberar a rota de saída, o canal `index=1` zerado silencia completamente o áudio no nível do hardware.

## 3. Comandos de Diagnóstico e Inspeção

Para identificar se o dispositivo está sofrendo dessa mesma regressão de mapeamento no ALSA, utilize os seguintes comandos:

1. **Listar o cartão de áudio cadastrado:**

  Bash

```
aplay -l | grep -i "Fuxi"
```

2. **Inspecionar os controles físicos e registros ALSA do cartão (`FuxiH3`):**

  Bash

```
amixer -c FuxiH3 contents
```

3. **Identificar o canal zerado:**
   
   Procure na saída pelo controle `PCM Playback Volume` secundário (`index=1`):

  Plaintext

```
numid=10,iface=MIXER,name='PCM Playback Volume',index=1
  ; type=INTEGER,access=rw---R--,values=1,min=0,max=100,step=0
  : values=0
```

## 4. Testes e Métodos Alternativos (Avaliados)

Durante o troubleshooting, as seguintes abordagens foram testadas:

| **Método Testado**                                 | **Camada**      | **Resultado** | **Motivo da Falha**                                                                 |
| -------------------------------------------------- | --------------- | ------------- | ----------------------------------------------------------------------------------- |
| `quirk_alias` no `snd-usb-audio` (`modprobe.d`)    | Driver          | **Ineficaz**  | O parâmetro não substituiu o parsing da *Feature Unit* corrompida.                  |
| Alteração de Perfil no PipeWire (`Pro Audio`)      | Servidor de Som | **Parcial**   | Reexibe o dispositivo no PipeWire, mas o canal ALSA base continua zerado no driver. |
| Forçar `api.alsa.soft-mixer = true` no WirePlumber | Sessão/PipeWire | **Ineficaz**  | O bloqueio ocorre antes da camada do servidor de áudio do usuário.                  |
| Plugin `softvol` no ALSA (`/etc/asound.conf`)      | ALSA Userland   | **Ineficaz**  | A rota PCM contorna o PipeWire, mas não altera o registro de hardware `numid=10`.   |

## 5. Método de Correção Definitiva

### Correção Imediata via CLI

Para desbloquear a saída de som em tempo de execução, altere o valor do controle de hardware `numid=10` para 100%:

Bash

```
amixer -c FuxiH3 cset numid=10 100
```

### Automação Permanente via Regras de Udev

Para garantir que a alteração seja aplicada automaticamente sempre que o dongle USB for conectado ou o sistema for inicializado:

1. **Criar a regra no udev:**

  Bash

```
sudo bash -c 'cat << "EOF" > /etc/udev/rules.d/99-havit-fuxi-fix.rulesACTION=="add", SUBSYSTEM=="sound", ATTRS{idVendor}=="040b", ATTRS{idProduct}=="0897", RUN+="/usr/bin/amixer -c FuxiH3 cset numid=10 100"EOF'
```

2. **Persistir o estado no ALSA Control:**

  Bash

```
sudo alsactl store
```

3. **Recarregar as regras do `udevadm`:**

  Bash

```
sudo udevadm control --reload-rules && sudo udevadm trigger
```

## 6. Conclusão

A falha do headset Havit Fuxi-H3 no Kernel 7.2 não se trata de defeito físico ou quebra completa do driver, mas de uma **regressão de mapeamento dos controles do mixer USB**. A redefinição do estado do registro `numid=10` via `amixer`, automatizada por regra do `udev`, resolve permanentemente o problema sem a necessidade de compilação de módulos ou downgrade do kernel.

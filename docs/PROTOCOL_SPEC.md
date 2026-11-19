# Especificação de Protocolo BLE — BML X Pro Max 5

## 1. Endereçamento de Características (Confirmado)
- **Canal Primário de Comandos (Wearfit NUS 1):**
  - Service: `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
  - Write (App -> Watch): `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` (`Write Without Response`)
  - Notify (Watch -> App): `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` (`Notify`)
- **Canal Secundário de Dados Pesados (Wearfit NUS 2):**
  - Service: `6E400011-B5A3-F393-E0A9-E50E24DCCA9E`
  - Write (App -> Watch): `6E400012-B5A3-F393-E0A9-E50E24DCCA9E` (`Write Without Response`)
  - Notify (Watch -> App): `6E400013-B5A3-F393-E0A9-E50E24DCCA9E` (`Notify`)
- **Canal Auxiliar (`0xFF12`):**
  - Service: `0000FF12-0000-1000-8000-00805F9B34FB`
  - Write: `FF13` | Notify: `FF14` | Read/WriteNoResp: `FF15`

## 2. Estrutura de Frames (Hipótese ainda não testada — Validar na Fase 2)
Baseado na documentação open-source do protocolo Wearfit (Gadgetbridge):
- **Byte 0 (Header):** `0xAB` (início de frame padrão Wearfit)
- **Bytes 1–2 (Length):** Tamanho do payload em Big-Endian (2 bytes)
- **Byte 3 (Message ID / Type):** Identificador da categoria do comando
- **Byte 4 (Version / Sub-command):** Subtipo da operação
- **Byte 5+ (Payload):** Parâmetros específicos do comando

## 3. Tabela de Comandos Testados
| Comando | Canal | Bytes Enviados (Hex) | Resposta Recebida (Hex) | Status |
| :--- | :--- | :--- | :--- | :--- |
| Sincronização de Data/Hora | `6E400002` | `[A testar na Fase 2]` | `[Pendente]` | Hipótese ainda não testada |
| Leitura de Bateria | `6E400002` | `[A testar na Fase 2]` | `[Pendente]` | Hipótese ainda não testada |
| Encontrar Relógio (Vibrar) | `6E400002` | `[A testar na Fase 2]` | `[Pendente]` | Hipótese ainda não testada |
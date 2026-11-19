# Especificação de Protocolo BLE — BML X Pro Max 5 (`fwk_2.23`)

## 1. Canais GATT Confirmados
- **Serviço Principal de Comandos (`6E400001-B5A3-F393-E0A9-E50E24DCCA9E`):**
  - **TX (iPhone -> Relógio):** `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` (`Write Without Response`)
  - **RX (Relógio -> iPhone):** `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` (`Notify` — Confirmado)
- **Serviço Secundário / Transferência em Lote (`6E400011-B5A3-F393-E0A9-E50E24DCCA9E`):**
  - **TX (iPhone -> Relógio):** `6E400012-B5A3-F393-E0A9-E50E24DCCA9E` (`Write Without Response`)
  - **RX (Relógio -> iPhone):** `6E400013-B5A3-F393-E0A9-E50E24DCCA9E` (`Notify` — Confirmado)
- **Serviço `FF12`:** `FF14` rejeita `Notify`; ignorado na camada BLE.

## 2. Estrutura Binária dos Frames (Confirmada)
`[0xAB] [Len_Hi] [Len_Lo] [0xFF] [Cmd_ID] [Sub_Cmd] [Payload...]` (sem checksum final).

## 3. Tabela de Comandos e Telemetria Validados

| Operação | Direção | Frame Hexadecimal | Layout do Payload | Classificação |
| :--- | :--- | :--- | :--- | :--- |
| **Bateria e Carga** | Watch -> App | `AB 00 05 FF 91 80 [Carga] [Nivel]` | `[Carga]`: `00` fora / `01` carregando; `[Nivel]`: `0`–`100` (`0x42` = 66%) | **Confirmada** |
| **Heartbeat** | Watch -> App | `AB 00 04 FF 21 80 00` | Sinal periódico de vida da conexão | **Confirmada** |
| **Encontrar Relógio** | App -> Watch | `AB 00 04 FF 71 80 [01/00]` | `01` inicia vibração e toque; `00` interrompe | **Confirmada** |
| **Sincronizar Hora** | App -> Watch | `AB 00 0B FF 93 80 00 [YY_H] [YY_L] [MM] [DD] [HH] [MIN] [SS]` | Atualiza relógio. Ack: `AB 00 04 FF 7B 80 04` | **Confirmada** |
| **Pedir Sincronização** | App -> Watch | `AB 00 0A FF 51 80 00 [YY_H] [YY_L] [MM] [DD] [HH] [MIN]` | Dispara descarga histórica de passos, vitais e sono | **Confirmada** |
| **Resumo Diário** | Watch -> App | `AB 00 11 FF 51 08 [Steps(3B)] [Kcal(3B)] [DeepH] [DeepM] [LightH] [LightM] ...` | Totais acumulados do dia atual | **Confirmada** |
| **Snapshot Horário** | Watch -> App | `AB 00 19 FF 51 20 [YY-2000] [MM] [DD] [HH] [Steps(3B)] [Kcal(3B)] [HR] [SpO2] [SBP] [DBP] ...` | Métricas horárias de passos, calorias, FC, SpO2 e PA | **Confirmada** |
| **Amostra Horária FC** | Watch -> App | `AB 00 0B FF 51 0B [YY-2000] [MM] [DD] [HH] 00 [BPM] [BPM] 0B` | Leitura pontual de batimentos por hora | **Confirmada** |
| **Fases do Sono** | Watch -> App | `AB 00 0B FF 52 80 [YY-2000] [MM] [DD] [HH] [MIN] [Tipo] [Dur(2B)]` | `[Tipo]`: `01` Profundo, `02` Leve; `[Dur]`: minutos | **Confirmada** |
| **Medição Remota** | App -> Watch | `AB 00 04 FF 31 [0A/12] 01` | Sem retorno imediato; investigar subcomando na Fase 8 | **Parcialmente identificada** |
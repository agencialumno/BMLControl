# Matriz de Funcionalidades — BML Control

| Módulo | Funcionalidade | Classificação Atual | Evidência Técnica |
| :--- | :--- | :--- | :--- |
| **J — Bluetooth** | Scan, Identificação por MAC (`0xFFF0`) e Conexão GATT | **Confirmada** | MAC `414275A43FA2` visível no Manufacturer Data `0xFFF0`. |
| **J — Bluetooth** | Canais Dual-UART (`6E400001` e `6E400011`) + `FF12` | **Confirmada** | Mapeados via nRF Connect no iPhone 11. |
| **H — Configurações** | Sincronização de Data/Hora, 12h/24h, Levantar Pulso | **Parcialmente identificada** | Suportado pelo barramento `6E400001`; validar bytes na Fase 2. |
| **G — Funções Inteligentes** | Encontrar Relógio, Clima, Alarmes, Não Perturbe | **Parcialmente identificada** | Suportado pelo SDK Wearfit `2.23`; validar bytes na Fase 2. |
| **F — Notificações** | Chamadas, WhatsApp, Instagram, SMS (via ANCS) | **Parcialmente identificada** | Suportado pelo iOS + comando de habilitação no `6E400001`. |
| **A/B/C/D — Métricas** | Bateria, Passos, FC, SpO2, Sono | **Parcialmente identificada** | Trafega via notificações `6E400003` / `6E400013`. |
| **E — Watch Faces** | Criação e Upload de Mostradores | **Parcialmente identificada** | Canal dedicado `6E400011` (`0012`/`0013`) presente no firmware. |
| **H — Firmware OTA** | Atualização de Firmware via `FE59` | **Bloqueada por Segurança** | Exige binário assinado pelo fabricante; fora do escopo por segurança. |
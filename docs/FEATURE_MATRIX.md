# Matriz de Funcionalidades — BML Control

| Módulo | Funcionalidade | Classificação Atual | Evidência Técnica |
| :--- | :--- | :--- | :--- |
| **J — Bluetooth** | Scan, Filtro MAC `0xFFF0` (`414275A43FA2`), Dual-UART | **Confirmada** | Validado no iPhone 11 via nRF Connect. |
| **A — Dashboard** | Bateria (`0x91`), Passos, Calorias (`0x51 0x08`) | **Confirmada** | Decodificado dos logs reais do X5 Pro Max. |
| **B — Saúde** | Histórico de FC, SpO2 e Pressão Arterial (`0x51 0x20` / `0x0B`) | **Confirmada** | Decodificado dos logs reais (`HR`, `SpO2`, `SBP/DBP`). |
| **C — Atividades** | Passos, Calorias e Evolução Horária (`0x51 0x20`) | **Confirmada** | Decodificado dos logs reais do X5 Pro Max. |
| **D — Sono** | Duração, Horários e Fases Profundo/Leve (`0x52 0x80`) | **Confirmada** | Decodificado dos logs reais do X5 Pro Max. |
| **G — Funções Inteligentes** | Encontrar Relógio (`0x71`) e Sincronização de Hora (`0x93`) | **Confirmada** | Validado fisicamente no pulso na Fase 2. |
| **F — Notificações** | Chamadas, WhatsApp, Instagram, SMS (ANCS + flags) | **Parcialmente identificada** | Implementar na Fase 9 após pareamento do app. |
| **H — Configurações** | Formato 12/24h, Levantar Pulso, Alarmes, Não Perturbe | **Parcialmente identificada** | Protocolo Wearfit mapeado; validar na Fase 9/11. |
| **E — Watch Faces** | Criação e Upload via canal `6E400011` (`0012`/`0013`) | **Parcialmente identificada** | Barramento presente; investigar na Fase 10. |
| **H — Firmware OTA** | Atualização via `FE59` | **Bloqueada por Segurança** | Risco de brick sem binário oficial assinado. |
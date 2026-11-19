# Matriz de Funcionalidades — BML Control

| Módulo | Funcionalidade | Classificação Atual | Evidência Técnica |
| :--- | :--- | :--- | :--- |
| **J — Bluetooth** | Scan, Filtro MAC `0xFFF0`, Conexão e Reconexão | **Confirmada** | Validado fisicamente no iPhone 11. |
| **I — Persistência** | Armazenamento local offline em SwiftData sem duplicação | **Confirmada** | Implementado na Fase 5 (`DailyActivityRecord`, `HourlyVitalSample`, `SleepSegmentRecord`). |
| **A — Dashboard** | Bateria (`0x91`), Passos, Calorias (`0x51 0x08`) | **Confirmada** | Decodificado e persistido localmente. |
| **B — Saúde** | Histórico de FC, SpO2 e Pressão (`0x51 0x20` / `0x0B`) | **Confirmada** | Decodificado e persistido localmente. |
| **C — Atividades** | Passos, Calorias e Evolução Horária (`0x51 0x20`) | **Confirmada** | Decodificado e persistido localmente. |
| **D — Sono** | Duração, Horários e Fases Profundo/Leve (`0x52 0x80`) | **Confirmada** | Decodificado e persistido localmente. |
| **G — Funções Inteligentes** | Encontrar Relógio (`0x71`) e Sincronização de Hora (`0x93`) | **Confirmada** | Validado fisicamente no pulso. |
| **H — Configurações** | Levantar Pulso (`0x77`), Formato 12/24h (`0x7C`), Meta (`0x74`) | **Confirmada** | Validado fisicamente no pulso na Fase 4. |
| **H — Configurações** | Modo Não Perturbe (`0x76`) | **Parcialmente identificada** | Toggle simples de 1 byte não surtiu efeito; investigar payload com horários na Fase 9. |
| **F — Notificações** | Chamadas, WhatsApp, Instagram, SMS (ANCS + flags) | **Parcialmente identificada** | Planejado para a Fase 9. |
| **E — Watch Faces** | Criação e Upload via canal `6E400011` (`0012`/`0013`) | **Parcialmente identificada** | Planejado para a Fase 10. |
| **H — Firmware OTA** | Atualização via `FE59` | **Bloqueada por Segurança** | Fora do escopo por risco de brick. |
# Matriz de Funcionalidades — BML Control

| Módulo | Funcionalidade | Classificação Atual | Evidência Técnica |
| :--- | :--- | :--- | :--- |
| **J — Bluetooth** | Scan, Filtro MAC `0xFFF0`, Conexão, Reconexão e State Restoration | **Confirmada** | Validado fisicamente no iPhone 11 (`CBCentralManagerOptionRestoreIdentifierKey`). |
| **I — Persistência** | Armazenamento local offline em SwiftData sem duplicação | **Confirmada** | Validado na Fase 5. |
| **A — Dashboard & UI** | Design System Adaptativo, 5 Abas e Ícone Oficial | **Confirmada** | Implementado nas Fases 6 e 7. |
| **B/C/D — Gráficos Saúde** | Gráficos `Swift Charts` (Dia / Semana / Mês) para Vitais, Passos e Sono | **Confirmada** | Implementado na Fase 7 com `HealthAnalyticsEngine`. |
| **G — Funções Inteligentes** | Encontrar Relógio (`0x71`) e Sincronização de Hora (`0x93`) | **Confirmada** | Validado fisicamente no pulso. |
| **H — Configurações** | Levantar Pulso (`0x77`), Formato 12/24h (`0x7C`), Meta (`0x74`) | **Confirmada** | Validado fisicamente no pulso na Fase 4. |
| **F — Notificações** | Chamadas, WhatsApp, Instagram, SMS (ANCS + flags) | **Parcialmente identificada** | Próxima etapa (Fase 8/9). |
| **E — Watch Faces** | Criação e Upload via canal `6E400011` (`0012`/`0013`) | **Parcialmente identificada** | Planejado para a Fase 10. |
| **H — Firmware OTA** | Atualização via `FE59` | **Bloqueada por Segurança** | Fora do escopo por risco de brick. |
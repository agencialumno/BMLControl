# Matriz de Funcionalidades — BML Control

| Módulo | Funcionalidade | Classificação Atual | Evidência Técnica |
| :--- | :--- | :--- | :--- |
| **J — Bluetooth** | Scan, Filtro MAC `0xFFF0`, Conexão, Reconexão e State Restoration | **Confirmada** | Validado fisicamente no iPhone 11. |
| **I — Persistência** | Armazenamento local offline em SwiftData sem duplicação | **Confirmada** | Validado na Fase 5. |
| **A — Dashboard & UI** | Design System Adaptativo, 5 Abas e Ícone Oficial | **Confirmada** | Validado nas Fases 6 e 7. |
| **B/C/D — Gráficos Saúde** | Gráficos `Swift Charts` (Dia / Semana / Mês) para Vitais, Passos e Sono | **Confirmada** | Validado fisicamente na Fase 7. |
| **G — Funções Inteligentes** | Encontrar Relógio (`0x71`) e Sincronização de Hora (`0x93`) | **Confirmada** | Validado fisicamente no pulso. |
| **H — Configurações** | Levantar Pulso (`0x77`), Formato 12/24h (`0x7C`), Meta (`0x74`) | **Confirmada** | Validado fisicamente no pulso. |
| **F — Notificações** | Chamadas, WhatsApp, Instagram, Telegram, SMS (ANCS + `0x72`) | **Hipótese ainda não testada** | Implementado na Fase 8 para validação no hardware. |
| **G — Clima, Alarmes, Câmera** | Clima Open-Meteo (`0x7E`), Alarmes (`0x73`), Câmera (`0x79`) | **Hipótese ainda não testada** | Implementado na Fase 8 para validação no hardware. |
| **E — Watch Faces** | Criação e Upload via canal `6E400011` (`0012`/`0013`) | **Parcialmente identificada** | Planejado para a Fase 10. |
| **H — Firmware OTA** | Atualização via `FE59` | **Bloqueada por Segurança** | Fora do escopo por risco de brick. |
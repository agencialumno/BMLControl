# Matriz de Funcionalidades — BML Control

| Módulo | Funcionalidade | Classificação Atual | Evidência Técnica |
| :--- | :--- | :--- | :--- |
| **J — Bluetooth** | Scan, Filtro MAC `0xFFF0`, Conexão e Reconexão | **Confirmada** | Validado fisicamente no iPhone 11 com o X5 Pro Max. |
| **A — Dashboard** | Bateria (`0x91`), Passos, Calorias (`0x51 0x08`) | **Confirmada** | Decodificado e testado com pacotes reais. |
| **B — Saúde** | Histórico de FC, SpO2 e Pressão (`0x51 0x20` / `0x0B`) | **Confirmada** | Decodificado dos logs reais do X5 Pro Max. |
| **C — Atividades** | Passos, Calorias e Evolução Horária (`0x51 0x20`) | **Confirmada** | Decodificado dos logs reais do X5 Pro Max. |
| **D — Sono** | Duração, Horários e Fases Profundo/Leve (`0x52 0x80`) | **Confirmada** | Decodificado dos logs reais do X5 Pro Max. |
| **G — Funções Inteligentes** | Encontrar Relógio (`0x71`) e Sincronização de Hora (`0x93`) | **Confirmada** | Validado fisicamente no pulso. |
| **H — Configurações** | Levantar Pulso (`0x77`), 12/24h (`0x7C`), DND (`0x76`), Meta (`0x74`) | **Hipótese ainda não testada** | Implementado no BMLCommandBuilder para validação física na Fase 4. |
| **F — Notificações** | Chamadas, WhatsApp, Instagram, SMS (ANCS + flags) | **Parcialmente identificada** | Planejado para a Fase 9. |
| **E — Watch Faces** | Criação e Upload via canal `6E400011` (`0012`/`0013`) | **Parcialmente identificada** | Planejado para a Fase 10. |
| **H — Firmware OTA** | Atualização via `FE59` | **Bloqueada por Segurança** | Fora do escopo por risco de brick. |
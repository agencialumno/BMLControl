# Perfil de Hardware — BML X Pro Max 5

## 1. Identificação Geral (Confirmada)
- **Nome Comercial:** BML X Pro Max 5 (SZ BML)
- **Nome Interno do Sistema:** Wearfit
- **Nome Bluetooth (BLE):** `X5 Pro Max`
- **Aplicativo Original Confirmado:** Wearfit Pro (Edição `7.10.29`)
- **Endereço MAC Físico:** `41:42:75:A4:3F:A2`
- **Versão de Firmware:** `V1.06`
- **Versão de Kernel / SDK:** `YM0242-1_[fwk_2.23]_[sdk_2.23]_[app_2.23]`

## 2. Ambiente de Execução iOS (Confirmado)
- **Dispositivo de Teste:** iPhone 11 (`MHDA3BR/A`)
- **Versão do Sistema:** iOS 26.5
- **Deployment Target Definido para Build:** iOS 17.0+ (Compatível com iOS 26.5)

## 3. Dados de Anúncio BLE — Advertisement Data (Confirmado)
- **Connectable:** `Yes`
- **Manufacturer Data:** Company ID `0xFFF0` | Payload Hex: `4142 75A4 3FA2` (MAC Físico)
- **Service Data 1:** UUID `0x3802` | Payload Hex: `4142 75A4 3FA2` (MAC Físico)
- **Service Data 2:** UUID `0x3A8E` | Payload Hex: `3431 3432 4132` (ASCII `"4142A2"`)
- **Flag DFU:** `Connection is required for DFU`

## 4. Identificação do Chipset (SoC)
- **Status Atual:** Parcialmente identificada
- **Arquitetura Detectada:** SoC Dual-Mode (BLE + BT Classic) com prefixo MAC `41:42` (`"AB"` — Bluetrum AB568x/AB569x ou Realtek RTL8762DK) executando SDK Wearfit `2.23` com barramento Dual-NUS e Secure DFU (`0xFE59`).

## 5. Árvore GATT Confirmada (Via nRF Connect no iPhone 11)

| Serviço (UUID) | Característica (UUID) | Propriedades | Papel Arquitetural |
| :--- | :--- | :--- | :--- |
| `1800` (Generic Access) | Padrão BLE | Padrão | Identificação básica GAP |
| `1801` (Generic Attribute) | Padrão BLE | Padrão | Controle de alteração de serviços |
| `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` | `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` | `Write Without Response` | **Canal 1 RX:** Envio de comandos principais (iPhone -> Relógio) |
| `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` | `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` | `Notify` (`2902`) | **Canal 1 TX:** Respostas e telemetria de sensores (Relógio -> iPhone) |
| `6E400011-B5A3-F393-E0A9-E50E24DCCA9E` | `6E400012-B5A3-F393-E0A9-E50E24DCCA9E` | `Write Without Response` | **Canal 2 RX:** Transferência em lote / Watch Faces / Clima |
| `6E400011-B5A3-F393-E0A9-E50E24DCCA9E` | `6E400013-B5A3-F393-E0A9-E50E24DCCA9E` | `Notify` (`2902`) | **Canal 2 TX:** Confirmação de blocos de dados em lote |
| `FF12` | `FF13` | `Write` | **Canal 3:** Escrita de controle auxiliar / áudio |
| `FF12` | `FF14` | `Notify` (`2902`) | **Canal 3:** Notificações auxiliares |
| `FF12` | `FF15` | `Read`, `Write Without Response` | **Canal 3:** Leitura/escrita rápida de estado |
| `FE59` (Secure DFU) | `8EC90001-F315-4F60-9FB8-838830DAEA50` | `Write`, `Notify` (`2902`) | **OTA Control Point:** Não utilizar sem binário oficial |
| `FE59` (Secure DFU) | `8EC90002-F315-4F60-9FB8-838830DAEA50` | `Read`, `Write Without Response` | **OTA Packet:** Não utilizar sem binário oficial |
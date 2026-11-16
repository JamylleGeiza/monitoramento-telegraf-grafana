# Demo: Monitoramento com Telegraf + InfluxDB + Grafana (Vagrant)

Uma VM Ubuntu 22.04 que sobe sozinha com:

| Ferramenta | Papel | Porta |
|---|---|---|
| **Telegraf** | coleta métricas (CPU, memória, disco, rede) a cada 10s | – |
| **InfluxDB 2** | guarda as métricas (banco de séries temporais) | 8086 |
| **Grafana** | mostra os painéis | 3000 |

Fluxo: `Telegraf → InfluxDB → Grafana`

## Pré-requisitos

- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://developer.hashicorp.com/vagrant)
- Internet (a VM baixa os pacotes na primeira vez)

## Como subir

```bash
cd monitoramento-vagrant
vagrant up        # demora ~5-10 min na primeira vez
```

Acesse no navegador:

- **Grafana:** http://localhost:3000 (usuário `admin`, senha `admin`; ele pede para trocar, pode pular)
  - O painel **"Infraestrutura - Telegraf"** já aparece em *Dashboards*
- **InfluxDB:** http://localhost:8086 (usuário `admin`, senha `admin12345`)

## Roteiro sugerido para a apresentação

1. **Mostrar o Vagrantfile e o provision.sh**: "infraestrutura como código", uma VM reproduzível com um comando.
2. `vagrant up` (de preferência já rodado antes; mostrar só o final do log).
3. **Mostrar o `telegraf.conf`**: seção `inputs` (o que coleta) e `outputs` (para onde envia).
4. **Mostrar o InfluxDB** (Data Explorer, bucket `telegraf`): os dados chegando.
5. **Abrir o Grafana**: datasource já configurado + dashboard com CPU, memória e disco.
6. **Gerar carga ao vivo** e ver o gráfico subir:

```bash
vagrant ssh -c "stress-ng --cpu 2 --vm 1 --vm-bytes 512M --timeout 90s"
```

## Comandos úteis

```bash
vagrant ssh                              # entrar na VM
sudo systemctl status telegraf grafana-server influxdb
sudo journalctl -u telegraf -f           # logs do Telegraf
telegraf --config /etc/telegraf/telegraf.conf --test   # testa a coleta sem enviar
vagrant halt                             # desliga a VM
vagrant destroy -f                       # apaga tudo
```

## Problemas comuns

- **Windows:** se o `provision.sh` falhar com erro de `\r`, o arquivo foi salvo com quebra de linha CRLF. Converta para LF (no VS Code: canto inferior direito, clique em "CRLF" e escolha "LF").
- **Porta 3000 ocupada:** troque `host: 3000` por outra porta no Vagrantfile.
- **Dashboard sem dados:** espere ~30s depois do `vagrant up` e confira se o Telegraf está ativo (`systemctl status telegraf`).

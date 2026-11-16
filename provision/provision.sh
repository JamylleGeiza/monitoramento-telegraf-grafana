set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

P=/vagrant/provision
INFLUX_USER=admin
INFLUX_PASS=admin12345
INFLUX_ORG=ifpe
INFLUX_BUCKET=telegraf
INFLUX_TOKEN=token-demo-ifpe

echo ">>> [1/6] Dependências"
apt-get update -y
apt-get install -y curl gnupg apt-transport-https ca-certificates stress-ng

echo ">>> [2/6] Repositórios oficiais (InfluxData e Grafana)"
mkdir -p /etc/apt/keyrings
curl -fsSL https://repos.influxdata.com/influxdata-archive.key \
  | gpg --batch --yes --dearmor -o /etc/apt/keyrings/influxdata.gpg
echo "deb [signed-by=/etc/apt/keyrings/influxdata.gpg] https://repos.influxdata.com/debian stable main" \
  > /etc/apt/sources.list.d/influxdata.list

curl -fsSL https://apt.grafana.com/gpg.key \
  | gpg --batch --yes --dearmor -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
  > /etc/apt/sources.list.d/grafana.list

apt-get update -y
apt-get install -y influxdb2 influxdb2-cli telegraf grafana

echo ">>> [3/6] InfluxDB (banco de séries temporais)"
systemctl enable --now influxdb
until curl -s http://localhost:8086/health | grep -q '"status":"pass"'; do
  echo "aguardando InfluxDB..."; sleep 2
done

# Configuração inicial: só roda se o token ainda não funcionar
if ! influx bucket list --org "$INFLUX_ORG" --token "$INFLUX_TOKEN" >/dev/null 2>&1; then
  influx setup \
    --username "$INFLUX_USER" --password "$INFLUX_PASS" \
    --org "$INFLUX_ORG" --bucket "$INFLUX_BUCKET" \
    --token "$INFLUX_TOKEN" --retention 0 --force
fi

# Confere que o token e o bucket realmente existem; se não, aborta com erro claro
if ! influx bucket list --org "$INFLUX_ORG" --token "$INFLUX_TOKEN" | grep -q "$INFLUX_BUCKET"; then
  echo "ERRO: o InfluxDB não foi configurado corretamente (token/bucket ausentes)." >&2
  exit 1
fi

echo ">>> [4/6] Telegraf (coletor de métricas)"
cp "$P/telegraf.conf" /etc/telegraf/telegraf.conf
systemctl enable telegraf
systemctl restart telegraf

echo ">>> [5/6] Grafana (datasource e dashboard já provisionados)"
mkdir -p /etc/grafana/provisioning/datasources \
         /etc/grafana/provisioning/dashboards \
         /var/lib/grafana/dashboards
cp "$P/grafana-datasource.yaml" /etc/grafana/provisioning/datasources/influxdb.yaml
cp "$P/grafana-dashboards.yaml" /etc/grafana/provisioning/dashboards/telegraf.yaml
cp "$P/dashboard-infra.json"    /var/lib/grafana/dashboards/dashboard-infra.json
chown -R grafana:grafana /var/lib/grafana/dashboards

systemctl enable --now grafana-server
systemctl restart grafana-server

echo ">>> [6/6] Pronto!"
echo "Grafana : http://localhost:3000  (admin / admin)"
echo "InfluxDB: http://localhost:8086  ($INFLUX_USER / $INFLUX_PASS)"
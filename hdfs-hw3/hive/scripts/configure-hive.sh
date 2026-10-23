#!/usr/bin/env bash
set -euo pipefail

export HIVE_HOME=/opt/hive
export HIVE_CONF_DIR=/opt/hive/conf
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop

if [[ "$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='hive'")" != 1 ]]; then
    sudo -u postgres createuser --pwprompt hive
fi

if [[ "$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='metastore'")" != 1 ]]; then
    sudo -u postgres createdb --owner=hive metastore
fi

python3 <<'PY'
import getpass
import xml.etree.ElementTree as ET

password = getpass.getpass('Пароль hive в PostgreSQL: ')
settings = {
    'javax.jdo.option.ConnectionURL': 'jdbc:postgresql://localhost:5432/metastore',
    'javax.jdo.option.ConnectionDriverName': 'org.postgresql.Driver',
    'javax.jdo.option.ConnectionUserName': 'hive',
    'javax.jdo.option.ConnectionPassword': password,
    'hive.metastore.uris': 'thrift://localhost:9083',
    'hive.metastore.warehouse.dir': '/user/hive/warehouse',
    'hive.metastore.schema.verification': 'true',
    'datanucleus.schema.autoCreateAll': 'false',
    'metastore.metastore.event.db.notification.api.auth': 'false',
    'hive.server2.thrift.bind.host': '127.0.0.1',
    'hive.server2.thrift.port': '10000',
    'hive.server2.enable.doAs': 'false',
}
root = ET.Element('configuration')
for name, value in settings.items():
    prop = ET.SubElement(root, 'property')
    ET.SubElement(prop, 'name').text = name
    ET.SubElement(prop, 'value').text = value

path = '/opt/hive/conf/hive-site.xml'
import os
fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
with os.fdopen(fd, 'wb') as f:
    ET.ElementTree(root).write(f, encoding='utf-8', xml_declaration=True)
os.chmod(path, 0o600)
PY

if [[ "$(sudo -u postgres psql -d metastore -tAc "SELECT to_regclass('public.\"VERSION\"') IS NOT NULL")" != t ]]; then
    "$HIVE_HOME/bin/schematool" -dbType postgres -initSchema
fi
"$HIVE_HOME/bin/schematool" -dbType postgres -info

sudo -u hadoop "$HADOOP_HOME/bin/hdfs" dfs -mkdir -p /user/hive/warehouse /user/team /tmp
sudo -u hadoop "$HADOOP_HOME/bin/hdfs" dfs -chown team:team /user/hive/warehouse /user/team
sudo -u hadoop "$HADOOP_HOME/bin/hdfs" dfs -chmod 1777 /tmp

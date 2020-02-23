#!/bin/bash
[[ -n ${DEBUG} ]] && set -ex || set -e

export MYSQL_ROOT_PASSWORD=''
export MYSQL_USER='mysql'
export MYSQL_PASSWORD='mysql'
export MYSQL_DATABASE='mysql'
export MYSQL_HOST='mysql'

cid="$(
	docker run -d \
	    -e DEBUG \
		-e MYSQL_ROOT_PASSWORD \
		-e MYSQL_USER \
		-e MYSQL_PASSWORD \
		-e MYSQL_DATABASE \
		-e MYSQL_PLUGIN_LOAD=auth_pam \
		--name ${MYSQL_HOST} \
		${IMAGE}
)"
trap 'docker rm -vf "${cid}" > /dev/null EXIT'

mysql() {
	docker run --rm -i \
	    -e DEBUG -e MYSQL_USER -e MYSQL_ROOT_PASSWORD -e MYSQL_PASSWORD -e MYSQL_DATABASE \
	    -v /tmp:/mnt/backups \
	    --link ${MYSQL_HOST}:${MYSQL_HOST} \
	    ${IMAGE} \
	    "${@}" \
	    host=${MYSQL_HOST}
}

mysql make check-ready delay_seconds=5 wait_seconds=5 max_try=12
mysql make mysql-upgrade
mysql make mysql-check

mysql make query query="CREATE TABLE test (a INT, b INT, c VARCHAR(255))"
[ "$(mysql make query-silent query='SELECT COUNT(*) FROM test')" = 0 ]
mysql make query query="INSERT INTO test VALUES (1, 2, 'hello')"
[ "$(mysql make query-silent query='SELECT COUNT(*) FROM test')" = 1 ]
mysql make query query="INSERT INTO test VALUES (2, 3, 'goodbye!')"
[ "$(mysql make query-silent query='SELECT COUNT(*) FROM test')" = 2 ]
mysql make query query="DELETE FROM test WHERE a = 1"
[ "$(mysql make query-silent query='SELECT COUNT(*) FROM test')" = 1 ]
mysql make query query="DELETE FROM test WHERE a = 1"
[ "$(mysql make query-silent query='SELECT c FROM test')" = 'goodbye!' ]
mysql make query query="DELETE FROM test WHERE a = 1"
mysql make mysql-check

mysql make query query="CREATE TABLE cache_this (a INT, b INT, c VARCHAR(255))"
mysql make query query="CREATE TABLE cache_that (a INT, b INT, c VARCHAR(255))"
mysql make query query="INSERT INTO cache_this VALUES (1, 2, 'hello')"
mysql make query query="INSERT INTO cache_that VALUES (1, 2, 'hello')"
mysql make mysql-check

[ "$(mysql make query-silent query='SELECT COUNT(*) FROM cache_this')" = 1 ]
[ "$(mysql make query-silent query='SELECT COUNT(*) FROM cache_that')" = 1 ]

mysql make query query="CREATE TABLE test1 (a INT, b INT, c VARCHAR(255))"
mysql make query query="CREATE TABLE test2 (a INT, b INT, c VARCHAR(255))"
mysql make query query="INSERT INTO test1 VALUES (1, 2, 'hello')"
mysql make query query="INSERT INTO test2 VALUES (1, 2, 'hello!')"
mysql make mysql-check

mysql make backup filepath="/mnt/backups/export.sql.gz" 'ignore="test1;test2;cache_%;test3"'
mysql make query query="DROP DATABASE mysql"
mysql make import source="/mnt/backups/export.sql.gz"
mysql make mysql-check

[ "$(mysql make query-silent query='SELECT COUNT(*) FROM cache_this')" = 0 ]
[ "$(mysql make query-silent query='SELECT COUNT(*) FROM cache_that')" = 0 ]

[ "$(mysql make query-silent query='SELECT COUNT(*) FROM test')" = 1 ]
[ "$(mysql make query-silent query='SELECT COUNT(*) FROM test1')" = 0 ]
[ "$(mysql make query-silent query='SELECT COUNT(*) FROM test2')" = 0 ]

mysql make import source="" #todo, test with real sql files.
mysql make import source=""
mysql make mysql-check
.PHONY: import backup query query-silent query-root check-ready check-live

check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Required parameter is missing: $1$(if $2, ($2))))

command = mysqladmin -uroot -p${root_password} -h${host} status &> /dev/null
user ?= $(MYSQL_USER)
password ?= $(MYSQL_PASSWORD)
db ?= $(MYSQL_DATABASE)
root_password ?= $(MYSQL_ROOT_PASSWORD)
host ?= localhost
max_try ?= 1
wait_seconds ?= 1
delay_seconds ?= 0
ignore ?= ""

default: query

import:
	$(call check_defined, source)
	import $(user) $(root_password) $(host) $(db) $(source)

backup:
	$(call check_defined, filepath)
	backup $(root_password) $(host) $(db) $(filepath) $(ignore)

query:
	$(call check_defined, query)
	mysql -u$(user) -p$(password) -h$(host) -e "$(query)" $(db)

query-silent:
	$(call check_defined, query)
	@mysql --silent -u$(user) -p$(password) -h$(host) -e "$(query)" $(db)

query-root:
	$(call check_defined, query)
	mysql -p$(root_password) -h$(host) -e "$(query)" $(db)

mysql-upgrade:
	mysql_upgrade -uroot -p$(root_password) -h$(host)

mysql-check:
	mysqlcheck -uroot -p$(root_password) -h$(host) $(db)

check-ready:
	wait_for "$(command)" "MySQL" $(host) $(max_try) $(wait_seconds) $(delay_seconds)

check-live:
	@echo "OK"

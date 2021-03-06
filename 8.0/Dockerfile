ARG FROM=${FROM}

FROM $FROM

ENV GOSU_VERSION 1.7
ENV MYSQL_MAJOR 8.0
ENV MYSQL_VERSION 8.0.19-1debian9

RUN set -ex; \
	groupadd -r mysql && \
	useradd -r -g mysql mysql; \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		gnupg \
		dirmngr; \
	rm -rf /var/lib/apt/lists/*

RUN set -ex; \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		wget; \
	rm -rf /var/lib/apt/lists/*; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" && \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" && \
	export GNUPGHOME="$(mktemp -d)" && \
	gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu && \
	gpgconf --kill all && \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc && \
	chmod +x /usr/local/bin/gosu && \
	gosu nobody true && \
	apt-get purge -y --auto-remove \
		ca-certificates \
		wget

RUN set -ex; \
	mkdir /docker-entrypoint-initdb.d; \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		pwgen \
		openssl \
		perl \
		tzdata \
		xz-utils; \
	rm -rf /var/lib/apt/lists/*

RUN set -ex; \
	key='A4A9406876FCBD3C456770C88C718D3B5072E1F5'; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	gpg --batch --export "$key" > /etc/apt/trusted.gpg.d/mysql.gpg; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME"; \
	apt-key list > /dev/null

RUN echo "deb http://repo.mysql.com/apt/debian/ stretch mysql-${MYSQL_MAJOR}" > /etc/apt/sources.list.d/mysql.list

RUN { \
		echo mysql-community-server mysql-community-server/data-dir select ''; \
		echo mysql-community-server mysql-community-server/root-pass password ''; \
		echo mysql-community-server mysql-community-server/re-root-pass password ''; \
		echo mysql-community-server mysql-community-server/remove-test-db select false; \
	} | debconf-set-selections; \
	apt-get update && \
	apt-get install -y \
		mysql-community-client="${MYSQL_VERSION}" \
		mysql-community-server-core="${MYSQL_VERSION}"; \
	rm -rf /var/lib/apt/lists/* && \
	rm -rf /var/lib/mysql && \
	mkdir -p /var/lib/mysql /var/run/mysqld && \
	chown -R mysql:mysql /var/lib/mysql /var/run/mysqld && \
	chmod 777 /var/run/mysqld && \
	chmod -R 0755 /etc/mysql/ && \
	mkdir /var/lib/mysql-files && \
	chmod 777 /var/lib/mysql-files

VOLUME /var/lib/mysql
COPY config /etc/mysql/
COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat
ENTRYPOINT ["docker-entrypoint.sh"]
EXPOSE 3306 33060
CMD ["mysqld"]

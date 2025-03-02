FROM ghcr.io/tecnativa/docker-duplicity as base

ENV JOB_500_WHAT='dup full $SRC $DST'
ENV JOB_500_WHEN='weekly'

ENV JOB_999_WHAT='dup remove-all-but-n-full 3 --force $DST'
ENV JOB_999_WHEN='weekly'

FROM base as mysql

RUN apk add --no-cache mariadb-client \
    && mysqldump --version

ENV JOB_201_WHAT mysqldump --host=\"\$BKP_DB_SERVER\" -u \"\$BKP_DB_USER\" --password=\"\$BKP_DB_PASS\" -Q -e --create-options --all-databases > \"\$SRC/mysql-database-dump.sql\"
ENV JOB_201_WHEN='daily weekly'

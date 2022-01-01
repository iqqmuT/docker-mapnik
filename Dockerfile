FROM postgis/postgis:13-3.2

# Environment to run Mapnik.
# Contains Python 3 bindings and map data in PostgreSQL.

# Because default PGDATA /var/lib/postgresql/data is in VOLUME,
# it will not be persisted. Using different path.
ENV PGDATA=/var/lib/postgresql/persisteddata
ENV POSTGRES_PASSWORD=postgres
ENV CARTO_VERSION=5.4.0

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    fonts-hanazono \
    fonts-noto-cjk \
    fonts-noto-hinted \
    fonts-noto-unhinted \
    gdal-bin \
    osm2pgsql \
    python3-mapnik \
    python3-requests \
    python3-psycopg2 \
    python3-yaml \
    ttf-unifont \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# install openstreetmap-carto into /opt/osm
RUN cd /opt && \
    curl -L https://github.com/gravitystorm/openstreetmap-carto/archive/v${CARTO_VERSION}.tar.gz \
    | tar xzf - && \
    mv openstreetmap-carto-${CARTO_VERSION} osm

WORKDIR /opt/osm

# Helper scripts to start/stop db
COPY start_db.sh /usr/local/bin/start_db.sh
COPY stop_db.sh /usr/local/bin/stop_db.sh

# variables for tune-osm2pgsql.sh
ENV PG_WORK_MEM=50MB
ENV PG_MAINTENANCE_WORK_MEM=5GB
COPY tune-osm2pgsql.sh /docker-entrypoint-initdb.d/tune-osm2pgsql.sh

# Copy tune-postgis.sh script to special dir that initialize-postgres.sh will run.
# Modify docker-entrypoint.sh from postgis docker image and
# run it to initialize postgres database
RUN cp scripts/tune-postgis.sh /docker-entrypoint-initdb.d/tune-postgis.sh && \
    cd /usr/local/bin && \
    mv docker-entrypoint.sh initialize-postgres.sh && \
    sed -i 's/exec "/#exec "/g' initialize-postgres.sh && \
    ./initialize-postgres.sh postgres

# download map data
ENV OSM2PGSQL_NUMPROC=4
ENV OSM2PGSQL_DATAFILE=finland-latest.osm.pbf
RUN curl -L -o ${OSM2PGSQL_DATAFILE} http://download.geofabrik.de/europe/${OSM2PGSQL_DATAFILE}

# import data from file and online as postgres user
COPY import-data.sh /opt/osm/import-data.sh
# postgres need write permission
RUN chown postgres:postgres /opt/osm
RUN echo "" && \
    echo "-----------------------------------------------------------" && \
    echo "|                                                         |" && \
    echo "|      GO GRAB A CUP OF TEA. THIS WILL TAKE 15 MINS.      |" && \
    echo "|                                                         |" && \
    echo "-----------------------------------------------------------" && \
    echo ""

RUN gosu postgres ./import-data.sh && \
    rm ${OSM2PGSQL_DATAFILE}

# mapnik.xml is already built by iqqmut/cartocss Docker image
# https://hub.docker.com/repository/docker/iqqmut/cartocss
COPY mapnik.xml /opt/osm/mapnik.xml

# override parent ENTRYPOINT
ENTRYPOINT []

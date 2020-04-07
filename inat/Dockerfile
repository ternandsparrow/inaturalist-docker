FROM ruby:2.6.5-stretch as withDeps
WORKDIR /srv/inat/
ADD ./setup.sh ./docker/setup.sh
ADD ./inaturalist/Gemfile* ./inaturalist/package* ./
RUN bash ./docker/setup.sh


FROM withDeps
# make sure we don't clobber the files that were *actually used*
# so nobody gets confused when troubleshooting.
RUN \
  mkdir -p bak && \
  mv Gemfile* docker/setup.sh bak/
ADD ./inaturalist/ ./
ADD ./*.sh ./docker/
RUN \
  mv bak/Gemfile* . && \
  mv bak/setup.sh docker/ && \
  rm -r bak
ENV CONFIG_VOL_DIR=/srv/inat_config
RUN \
  ./node_modules/.bin/gulp webpack && \
  rm config/*.yml.example && \
  mkdir -p log/

EXPOSE 3000
ENTRYPOINT ["/bin/bash", "./docker/entrypoint.sh"]

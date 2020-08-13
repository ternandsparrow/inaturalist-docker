FROM node:12
ENV TARGET_DIR=/srv/inatapi

WORKDIR $TARGET_DIR
ADD ./iNaturalistAPI/ ./
ADD ./*.sh ./docker/
RUN chown -R 1000:1000 $TARGET_DIR
USER 1000:1000
RUN ./docker/setup.sh

EXPOSE 4000
ENTRYPOINT ["./docker/entrypoint.sh"]

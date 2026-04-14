FROM google/cloud-sdk
WORKDIR .
ENV MOUNT_DIR="/data"
#ENV MOUNT_BUCKET="gs://rws-data"

COPY ./*.sh ./
RUN chmod +x ./*.sh
CMD ["./setup.sh"]

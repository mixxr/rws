FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:slim
WORKDIR .
ENV MOUNT_DIR="/data"
#ENV MOUNT_BUCKET="gs://rws-data"

COPY ./*.sh ./
RUN chmod +x ./*.sh
CMD ["./setup.sh"]

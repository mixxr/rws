FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:slim
WORKDIR .

COPY ./*.sh ./
COPY ./*.sql ./
RUN chmod +x ./*.sh
CMD ["./setup.sh"]

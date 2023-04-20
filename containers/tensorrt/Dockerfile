FROM nvcr.io/nvidia/tensorrt:22.07-py3

WORKDIR /
ADD https://raw.githubusercontent.com/blakeblackshear/frigate/dev/docker/tensorrt_models.sh /tensorrt_models.sh

RUN chmod +x tensorrt_models.sh
RUN mkdir -p /tensorrt-models

CMD ["/tensorrt_models.sh"]

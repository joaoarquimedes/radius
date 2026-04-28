ARG ARCH
ARG DOCKER_IMAGE
FROM --platform=${ARCH} ${DOCKER_IMAGE}
LABEL description="LPIC-3 Security"

RUN apt clean && apt autoclean -y
RUN apt update -y && apt upgrade -y

# Install freeradius
RUN apt install -y curl iproute2 procps eapoltest
RUN apt install -y build-essential
# https://www.freeradius.org/ftp/pub/freeradius/freeradius-server-3.2.8.tar.gz

WORKDIR /usr/src
ARG FREERADIUS_VERSION
RUN curl -O https://www.freeradius.org/ftp/pub/freeradius/freeradius-server-${FREERADIUS_VERSION}.tar.gz
RUN tar -xzf freeradius-server-${FREERADIUS_VERSION}.tar.gz
WORKDIR /usr/src/freeradius-server-${FREERADIUS_VERSION}

RUN apt install -y libtalloc-dev libssh-dev
RUN ./configure --prefix=/usr/local/freeradius-${FREERADIUS_VERSION}
RUN make -j $(nproc)
RUN make install
RUN ln -s /usr/local/freeradius-${FREERADIUS_VERSION} /usr/local/freeradius

RUN rm -rf /usr/src/freeradius-server-${FREERADIUS_VERSION}*
RUN apt remove --purge -y build-essential
RUN apt autoremove --purge -y
RUN apt clean && apt autoclean -y

# Criando pastas
ARG USER_NAME
ARG GROUP_NAME
RUN mkdir -p /usr/local/freeradius/var/run/radiusd
RUN chown -R ${USER_NAME}:${GROUP_NAME} /usr/local/freeradius/var/run/radiusd
RUN chmod -R 755 /usr/local/freeradius/var/run/radiusd
RUN mkdir -p /usr/local/freeradius/var/log/radius/radutmp
RUN chown -R ${USER_NAME}:${GROUP_NAME} /usr/local/freeradius/var/log/radius/radutmp
RUN chmod -R 755 /usr/local/freeradius/var/log/radius/radutmp

ARG TZ
ENV TZ=${TZ}
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
RUN echo ${TZ} > /etc/timezone

COPY --chown=root:root --chmod=644 ./bashrc /root/.bashrc

ENV PATH="/usr/local/freeradius/sbin:/usr/local/freeradius/bin:${PATH}"
WORKDIR /usr/local/freeradius/etc/raddb

EXPOSE 1812/udp 1813/udp

# Inicialização com saída de log no stdout
CMD ["radiusd", "-fl", "stdout"]
# Inicialização modo debug. Somente para validação, usa-se os parâmetros -XC
# CMD ["radiusd", "-X"]

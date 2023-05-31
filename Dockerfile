FROM python:3.9 AS flax_build

# build arguments
ARG DEBIAN_FRONTEND=noninteractive 
ARG RELEASE

# set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# install build dependencies
RUN \
	apt-get update \
	&& apt-get install \
	--no-install-recommends -y \
		ca-certificates \
		curl \
		jq \
		lsb-release \
		sudo

# set workdir
WORKDIR /flax-blockchain

# fetch source
RUN \
	if [ -z ${RELEASE+x} ]; then \
	RELEASE=$(curl -u "${SECRETUSER}:${SECRETPASS}" -sX GET "https://api.github.com/repos/Flax-Network/flax-blockchain/releases/latest" \
	| jq -r ".tag_name"); \
	fi \
	&& git clone --branch "${RELEASE}" --recurse-submodules=mozilla-ca https://github.com/Flax-Network/flax-blockchain.git . \
	&& /bin/sh ./install.sh

FROM python:3.9-slim

# build arguments
ARG DEBIAN_FRONTEND=noninteractive

# environment variables
ENV \
        FLAX_ROOT=/root/.flax/mainnet \
        farmer_address= \
        farmer_port= \
        keys="generate" \
        log_level="INFO" \
        log_to_file="true" \
        outbound_peer_count="20" \
        peer_count="20" \
        plots_dir="/plots" \
        service="farmer" \
        testnet="false" \
        TZ="UTC" \
        upnp="true"

# legacy options
ENV \
	farmer="false" \
	harvester="false"

# set workdir
WORKDIR /flax-blockchain

# install dependencies
RUN \
	apt-get update \
	&& apt-get install \
	--no-install-recommends -y \
		tzdata \
	\
# set timezone
	\
	&& ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime \
	&& echo "$TZ" > /etc/timezone \
	&& dpkg-reconfigure -f noninteractive tzdata \
	\
# cleanup
	\
	&& rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

# set additional runtime environment variables
ENV \
	PATH=/flax-blockchain/venv/bin:$PATH

# copy build files
COPY --from=flax_build /flax-blockchain /flax-blockchain

# copy local files
COPY docker-*.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-*.sh

HEALTHCHECK --interval=1m --timeout=10s --start-period=20m \
  CMD /bin/bash /usr/local/bin/docker-healthcheck.sh || exit 1

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["docker-start.sh"]

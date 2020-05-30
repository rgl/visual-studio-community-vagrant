# escape=`
ARG WINDOWS_VERSION_TAG

FROM mcr.microsoft.com/windows/nanoserver:${WINDOWS_VERSION_TAG} as builder
WORKDIR C:/Users/ContainerUser
ADD https://github.com/portainer/portainer/releases/download/1.23.2/portainer-1.23.2-windows-amd64.tar.gz portainer.tgz
RUN tar xf portainer.tgz

FROM mcr.microsoft.com/windows/nanoserver:${WINDOWS_VERSION_TAG}
EXPOSE 9000
COPY --from=builder /Users/ContainerUser/portainer /app
# NB running as ContainerAdministrator is needed to access the docker named pipe.
USER ContainerAdministrator
RUN mkdir c:\data
VOLUME ["C:/data"]
WORKDIR /app
ENTRYPOINT ["/app/portainer.exe", "--no-auth", "--template-file", "templates.json"]

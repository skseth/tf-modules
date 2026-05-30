FROM mysql:8.0

# Use microdnf (for OL8/9-slim) or yum (for OL7) to install locale tools
USER root
RUN microdnf install -y glibc-locale-source glibc-langpack-en && \
    microdnf clean all

# Generate the desired locale
RUN localedef -i en_US -f UTF-8 en_US.UTF-8

# Set environment variables so MySQL and the shell use the new locale
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

ENV MYSQLSH_USER_CONFIG_HOME=/mysqlsh
ENV MYSQLSH_HISTFILE=/mysqlsh/history

# Create the directory structure as root first
RUN mkdir -p $MYSQLSH_USER_CONFIG_HOME/init.d && \
    chown -R mysql:mysql $MYSQLSH_USER_CONFIG_HOME
# Switch back to the mysql user
USER mysql

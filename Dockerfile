FROM centos:7

# 环境变量
ENV NVM_DIR=/root/.nvm \
    HOST=0.0.0.0 \
    PORT=1551

# 1) 基础依赖 + 换源到阿里云 + 清理缓存
RUN set -eux; \
    yum -y install curl ca-certificates && update-ca-trust; \
    cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak; \
    curl -fsSL -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo; \
    yum clean all && yum makecache; \
    yum -y update; \
    yum -y install git gcc-c++ make openssl-devel python tar xz unzip; \
    yum clean all && rm -rf /var/cache/yum

# 2) 安装 nvm + Node 16（并将 node/npm/npx 链接到 PATH）
RUN set -eux; \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash; \
    . "$NVM_DIR/nvm.sh"; \
    nvm install 16; \
    nvm alias default 16; \
    # 软链接，保证非交互 shell 也能直接用 node/npm/npx
    ln -s /root/.nvm/versions/node/v16.*/bin/node /usr/local/bin/node; \
    ln -s /root/.nvm/versions/node/v16.*/bin/npm  /usr/local/bin/npm; \
    ln -s /root/.nvm/versions/node/v16.*/bin/npx  /usr/local/bin/npx; \
    # 方便你进入容器调试时自动加载 nvm
    echo 'export NVM_DIR="$HOME/.nvm"' >> /root/.bashrc; \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' >> /root/.bashrc

# 3) 拉取项目（node 分支）
RUN git clone --branch node --depth 1 https://github.com/bg6cq/speedtest.git /root/speedtest
WORKDIR /root/speedtest

# 4) 安装生产依赖（优先使用 package-lock）
RUN set -eux; \
    npm ci --only=production || npm install --production

# 5) 声明数据目录（可选，与笔记一致）
RUN mkdir -p /myspeed/data
VOLUME ["/myspeed/data"]

# 6) 暴露端口并启动服务
EXPOSE 1551
CMD ["node", "src/Speedtest.js"]

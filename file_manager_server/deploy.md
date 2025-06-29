## 编译 file_manager_server
```
cargo build --release
```
编译完成后能得到 file_manager_server 可执行文件

## 部署
服务器端创建 /etc/systemd/system/file_manager_server.service, 并写入以下内容:
```
[Unit]
Description=Rust File Manager Server
After=network.target

[Service]
ExecStart=/<path>/file_manager_server port=8081 dir=/<文件存放地址>/
Restart=always
User=dx
Group=dx
Environment=RUST_BACKTRACE=1

[Install]
WantedBy=multi-user.target
```

然后执行以下命令, 启用file_manager_server
```
sudo systemctl enable file_manager_server
sudo systemctl start file_manager_server
```

查看服务运行状态
```
sudo systemctl status file_manager_server
```

### 配置 nginx
参考 nginx-example.conf 配置, 配置文件服务器和 file_manager_server
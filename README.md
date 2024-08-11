# remote_files

Remote file browser, currently only supports http file servers built by Nginx.

# Windows
Should work as is in debug mode (sqlite3.dll is bundled).
In release mode, add sqlite3.dll in same folder as your executable.

# Linux
libsqlite3 and libsqlite3-dev linux packages are required.
One time setup for Ubuntu (to run as root):
```
dart tool/linux_setup.dart
```
or
```
sudo apt-get -y install libsqlite3-0 libsqlite3-dev
```

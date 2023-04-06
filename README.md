
## 启动django服务器
```shell
cd ./server
python manage.py runserver 0.0.0.0:39980
```
## 添加字幕文件到 ./server/static/subtitles
- 注意字幕文件是一个`.zip`压缩包, 包含一个`.ass`或`.srt`的字幕文件, 二者应该同名

## 在potplayer中添加自己的字幕服务器
- 参考 `.potplayer_scripts/readme.md`.

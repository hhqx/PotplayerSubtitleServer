import glob
import zipfile
from pathlib import Path

from django.shortcuts import render, redirect

# Create your views here.
from django.http import HttpResponse

import os
from django.http import HttpResponseBadRequest, HttpResponseNotFound, FileResponse
from django.urls import reverse
from django.views.decorators.csrf import csrf_exempt

from server import settings

import os
from django.conf import settings
from django.http import HttpResponse

download_base = '/static/subtitles/'



def subtitle_list(request):
    subtitle_dir = os.path.join(settings.STATICFILES_DIRS[0], 'subtitles')

    # 获取所有字幕文件的文件名
    subtitle_files = [f for f in os.listdir(subtitle_dir) if os.path.isfile(os.path.join(subtitle_dir, f))]

    # 构建HTML列表
    items = ['<li><a href="/subtitle/download?file={0}">{0}</a></li>'.format(f) for f in subtitle_files]

    ret = '<results>{0}</results>'.format(''.join(items))

    # 将HTML列表返回给用户
    return HttpResponse(ret)


def search(request):
    # 获取查询参数
    file = request.GET.get('file', '')
    def get_down_load_url(name):
        return f'subtitle/download?file={name}'

    def list_to_xml(lst):
        n = len(lst)
        header = f'<pagination><current>1</current><count>1</count><results>{n}</results></pagination>'
        tpl = """
            <subtitle>
            <pid>{0}</pid>
            <title>{1}</title>
            <languageName>Chinese</languageName>
            <format>{2}</format>
            </subtitle>"""
        content = ""
        # for pid, title, fmt in [["test_ass.zip", "我自己的字幕", "srt"] for _ in range(n)]:
        for file in lst:
            if os.path.exists(file) and file.endswith(".zip"):
                # 打开zip文件
                with zipfile.ZipFile(file, 'r') as zip_file:
                    # 获取所有文件名列表
                    file_names = zip_file.namelist()
                    subtitle = file_names[0]
                fname = Path(subtitle).stem + ".zip"
                name, ext = os.path.splitext(fname)
                if '.' in ext:
                    ext = ext[1:]
                pid, title, fmt = get_down_load_url(fname), name, ext
            else:
                pid, title, fmt = "null", "not found", "null"
            content += tpl.format(pid, title, fmt)
        return f"<results>{header}{content}</results>"

    # 如果没有提供必要的查询参数，则返回错误响应
    if not file:
        return HttpResponseBadRequest()

    # 在目标目录中搜索匹配的字幕文件
    def match_str(files, s):
        """ 在potplayer传过来的字符串中_.之类的字符会变成空格, 这个丢弃第一个和最后一个word后在文件files中进行搜索 """
        segs = s.split()
        if len(segs) < 3:
            ans = files
        else:
            name = "_".join(segs[1:-1])
            ans = [file for file in files if name in Path(file).name]
        if not ans:
            # 若无匹配结果, 添加 Not Found
            ans = ["Not Found"]
        # print("Match Results:", s, ans)
        return ans

    # 在本地路径下搜索, 查找是否存在file相关的字幕文件
    db_files = glob.glob('static/subtitles/*.zip')
    subtitle_file = match_str(db_files, file)
    print('subtitle_file:', subtitle_file)

    # 如果找不到匹配的字幕文件，则返回 404 Not Found 响应
    if not subtitle_file:
        return HttpResponseNotFound()

    # 构造响应对象并返回
    ret = list_to_xml(subtitle_file)
    return HttpResponse(ret, content_type='application/xml')


def search_subtitles(request):
    # TODO: 从请求参数中获取字幕文件路径或内容
    # TODO: 根据字幕文件路径或内容，创建 HttpResponse 并返回

    # print(request)
    r = search(request)

    return r


def download_subtitle(request):
    file = request.GET.get('file')

    if not file:
        return HttpResponseBadRequest()

    filepath = os.path.join(settings.STATICFILES_DIRS[0] + '/subtitles', file)
    if not os.path.exists(filepath):
        return HttpResponseNotFound()

    def get_file(file_path):
        # 使用 FileResponse 读取文件并返回
        response = FileResponse(open(file_path, 'rb'), as_attachment=True, filename=Path(file_path).name)
        return response

    return get_file(filepath)
    # return redirect(download_base + file)


@csrf_exempt
def subtitle_search(request):
    """ 已弃用 """
    if request.method in {'POST', 'GET'}:
        # 从POST请求中获取电影文件名、大小等信息
        ap = request.POST.get('ap')
        ua = request.POST.get('ua')
        movie_name = request.POST.get('fn')
        movie_size = request.POST.get('fs')
        movie_hash = request.POST.get('fh')

        # 调用函数进行字幕搜索
        file = 'test_ass.zip'
        title = 'Subtitle Test'
        data = f"OK-2 fname:{file}|ftitle:{title}|fimdb:20|fyear:2023|fps:25|time:20230405||"
        print(data)

        # return HttpResponse("Hello, world!")
        return HttpResponse(data)
    else:
        # 如果不是POST请求，返回错误响应
        return HttpResponse('Method not allowed', status=405)

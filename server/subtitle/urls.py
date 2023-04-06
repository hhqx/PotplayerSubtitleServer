from django.urls import path

from . import views

urlpatterns = [
    path('', views.subtitle_list, name='get_subtitles_list'),
    path('search', views.search_subtitles, name='search_subtitles'),
    path('download', views.download_subtitle, name='download_subtitle'),
    # path('get_status', views.subtitle_search, name='subtitle_search'),
]

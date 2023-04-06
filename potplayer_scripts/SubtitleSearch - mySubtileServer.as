/*
	django subtitle server search by hqx based on opensubtitle
*/


// Set to your Server ip or domain
string Server_Base = "potplayer.server.hqx:39980";




string API_URL = "http://" + Server_Base + "/";
string GetTitle()
{
	return "mySubtileServer";
}

string GetVersion()
{
	return "1";
}

string GetDesc()
{
	return API_URL;
}

string GetLanguages()
{
	return "zh,en";
}

string ServerCheck(string User, string Pass)
{
	string ret = HostUrlGetString(API_URL);
	
	if (ret.empty()) return "fail";
	return "200 OK";
}
string SubtitleDownload(string id)
{
	string api = API_URL + "static/subtitles/" + id;
	return HostUrlGetString(api);
}
array<dictionary> SubtitleSearch_onetest(string MovieFileName, dictionary MovieMetaData)
{
	array<dictionary> ret;
	dictionary item;
	// item['id']='inner_204_in.mp4.ass';
	item['id']='test.zip';
	//item['url']=SubtitleDownload('test.zip');
	item['title']='xxx';
	item['year']='2023';
	item['time']='0405';
	item['imdb']='0';

	ret.insertLast(item);
	return ret;
}
array<dictionary> SubtitleSearch_v1(string MovieFileName, dictionary MovieMetaData)
{
	array<dictionary> ret;
	dictionary item;
	item['id']='test_ass.zip';
	//item['url']=SubtitleDownload('test.zip');
	item['title']='Test V1';
	item['year']='2023';
	item['time']='0405';
	item['imdb']='0';

	ret.insertLast(item);

	int64 size = 0;
	string title = string(MovieMetaData["title"]);
	string fileName = string(MovieMetaData["fileName"]);
	string content = "postAction=CheckSub";	

    content = content + "&ua=mpc-hc";
    content = content + "&ap=mpc-hc";
    content = content + "&fs=" + formatInt(size);
    content = content + "&fn=" + fileName;
	
	string api = API_URL + "subtitle/get_status";
	string data = HostUrlGetString(api, "MPC-HC/1.7.11", "Content-Type: application/x-www-form-urlencoded\r\n", content);
	if (!data.empty())
	{
		string status = data.substr(0, 4);
		
		if (status == "OK-2" || status == "OK-3")
		{
			data.erase(0, 5);
			int infoEnd = data.find("||");
			
			if (infoEnd >= 0)
			{
				dictionary item;
				string fileContents = data.substr(infoEnd + 2);
				
				item["fileContent"] = fileContents;
				item["title"] = title;
				item["lang"] = GetLanguages();
				
				data.erase(infoEnd);
				array<string> infos = data.split("|");
				for (int i = 0, len = infos.size(); i < len; i++)
				{
					string line = infos[i];
					
					if (!line.empty())
					{
						int p = line.find(":");
						
						if (p > 0)
						{
							string left = line.substr(0, p);
							string right = line.substr(p + 1);
						
							if (left == "fname") item["id"] = right;
							else if (left == "ftitle") item["title"] = right;
							else if (left == "fimdb") item["imdb"] = right;
							else if (left == "fyear") item["year"] = right;
							else if (left == "fps") item["fps"] = right;
							else if (left == "time") item["time"] = right;
						}
					}
				}
				ret.insertLast(item);
			}
		}
	}
	
	return ret;
}
string GetChildElementText(XMLElement element, string key)
{
	string ret = "";	
	XMLElement childElement = element.FirstChildElement(key);
	
	if (childElement.isValid()) ret = childElement.asString();
	return ret;
}
string HtmlSpecialCharsDecode(string str)
{
	str.replace("&amp;", "&");
	str.replace("&quot;", "\"");
	str.replace("&#039;", "'");
	str.replace("&lt;", "<");
	str.replace("&gt;", ">");
	str.replace("&rsquo;", "'");
	
	return str;
}
array<dictionary> SubtitleSearch_v2(string MovieFileName, dictionary MovieMetaData)
{
	array<dictionary> ret;
	/*
	dictionary item;
	// item['id']='inner_204_in.mp4.ass';
	item['id']='test.zip';
	//item['url']=SubtitleDownload('test.zip');
	item['title']='xxx';
	item['year']='2023';
	item['time']='0405';
	item['imdb']='0';
	ret.insertLast(item);
	*/

	int page = 1;
	int pages = 1;
	int results = 0;
	string title = string(MovieMetaData["title"]);
	string country = string(MovieMetaData["country"]);
	string year = string(MovieMetaData["year"]);
	string seasonNumber = string(MovieMetaData["seasonNumber"]);
	string episodeNumber = string(MovieMetaData["episodeNumber"]);
	
	title.replace("and", "");
	title.replace("%!", "");
	title.replace("%?", "");
	title.replace("%&", "");
	title.replace("%'", "");
	title.replace("%:", "");
	if (!country.empty()) title = title + " " + country;
	
	while (page <= pages)
	{
		int oldPage = page;
		string api = API_URL + "subtitle/search?sXML=1&sAKA=1";
		
		//if (!title.empty()) api = api + "&file=" + HostUrlEncode(title);
		if (!title.empty()) api = api + "&file=" + title;
		if (!year.empty()) api = api + "&sY=" + year;
		if (!seasonNumber.empty()) api = api + "&sTS=" + seasonNumber;
		if (!episodeNumber.empty()) api = api + "&sTE=" + episodeNumber;
		api = api + "&page=" + formatInt(page);
		
		string xml = HostUrlGetString(api);
		XMLDocument dxml;
		if (dxml.Parse(xml))
		{
			XMLElement rootElmt = dxml.FirstChildElement("results");
			
			if (rootElmt.isValid())
			{
				XMLElement paginationElmt = rootElmt.FirstChildElement("pagination");
				
				if (paginationElmt.isValid())
				{
					page = parseInt(GetChildElementText(paginationElmt, "current"));
					pages = parseInt(GetChildElementText(paginationElmt, "count"));
					results = parseInt(GetChildElementText(paginationElmt, "results"));
				}
				if (page > 1) break;
				
				if (results > 0)
				{
					XMLElement subtitleElmt = rootElmt.FirstChildElement("subtitle");
					
					while (subtitleElmt.isValid())
					{
						string pid = GetChildElementText(subtitleElmt, "pid");
						string title = GetChildElementText(subtitleElmt, "title");

						if (!pid.empty() && !title.empty())
						{
							dictionary item;

							item["id"] = pid;
							item["title"] = HtmlSpecialCharsDecode(title);
							
							string year = GetChildElementText(subtitleElmt, "year");
							if (!year.empty()) item["year"] = year;

							string url = GetChildElementText(subtitleElmt, "url");
							if (!url.empty()) item["url"] = url;

							string format = GetChildElementText(subtitleElmt, "format");
							if (format.empty() || format == "SubRip" || format == "N/A") item["format"] = "srt";
							else item["format"] = format;

							string languageName = GetChildElementText(subtitleElmt, "languageName");
							if (!languageName.empty()) item["language"] = languageName;

							string lang = GetChildElementText(subtitleElmt, "language");
							if (!lang.empty()) item["lang"] = lang;
							
							string tvSeason = GetChildElementText(subtitleElmt, "tvSeason");
							if (!tvSeason.empty()) item["seasonNumber"] = tvSeason;

							string tvEpisode = GetChildElementText(subtitleElmt, "tvEpisode");
							if (!tvEpisode.empty()) item["episodeNumber"] = tvEpisode;

							string cds = GetChildElementText(subtitleElmt, "cds");
							if (!cds.empty()) item["disc"] = cds;

							string downloads = GetChildElementText(subtitleElmt, "downloads");
							if (!downloads.empty()) item["downloadCount"] = downloads;

							string fps = GetChildElementText(subtitleElmt, "fps");
							if (!fps.empty()) item["fps"] = fps;
							
							ret.insertLast(item);
						}
						subtitleElmt = subtitleElmt.NextSiblingElement();
					}
				}
			}
		}
		page++;
		if (oldPage >= page) break;
	}	
	return ret;
}
array<dictionary> SubtitleSearch(string MovieFileName, dictionary MovieMetaData)
{
	array<dictionary> ret;
	//ret = SubtitleSearch_onetest(MovieFileName, MovieMetaData);
	//ret = SubtitleSearch_v1(MovieFileName, MovieMetaData);
	ret = SubtitleSearch_v2(MovieFileName, MovieMetaData);
	return ret;
}
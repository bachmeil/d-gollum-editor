import arsd.cgi;
import std.algorithm.iteration, std.algorithm.sorting, std.array, std.datetime.date;
import std.conv, std.datetime, std.file, std.path, std.process, std.stdio, std.string, std.uri;

enum attachdir = "/repos/attach201906";

void app(Cgi cgi) {
  cgi.setResponseContentType("text/html");
  if (!("dir" in cgi.cookies)) {
		cgi.setCookie("dir", std.file.getcwd() ~ "/");
	}
  string path = cgi.pathInfo;
  string data;
  switch(path) {
		case "/opentext":
			spawnShell("geany -i " ~ cgi.get["name"], null, Config.detached);
			break;
		case "/pdf":
			cgi.setResponseContentType("application/pdf");
			cgi.header(`Content-Disposition: attachment; filename="` ~ cgi.get["name"]);
			data = read(cgi.get["name"]).to!string;
			break;
		case "/email":
			cgi.setResponseContentType("message/rfc822");
			cgi.header(`Content-Disposition: attachment; filename="` ~ cgi.get["name"]);
			data = read(cgi.get["name"]).to!string;
			break;
		case "/wikiview":
			string fn = cgi.get["dir"] ~ "/" ~ cgi.get["file"] ~ ".md";
			if (!exists(fn)) {
				data = "File " ~ fn ~ " does not exist. " ~ `<a href="/wikicreate?dir=` ~ cgi.get["dir"] ~ `&file=` ~ cgi.get["file"] ~ `">Click here to create it.</a>`;
			} else {
				data = wikiView(fn, cgi.get["dir"], cgi.get["file"]);
			}
			break;
		case "/wikiviewalt":
			cgi.setResponseLocation("/wikiview?dir=" ~ dirName(cgi.get["f"]) ~ "&file=" ~ baseName(cgi.get["f"]));
			break;
		case "/quickwiki":
			string fn = Clock.currTime().toISOExtString();
			//string dir = executeShell("cat /var/lib/dbus/machine-id").output[0..$-1] ~ "/auto";
			string dir = "auto/";
			string cmd = "geany -i " ~ dir ~ fn ~ ".md";
			executeShell(cmd);
			cgi.setResponseLocation("/wikiview?dir=" ~ dir ~ "&file=" ~ fn);
			break;
		case "/viewquick":
			//string dir = executeShell("cat /var/lib/dbus/machine-id").output[0..$-1] ~ "/auto";
			string dir = "auto/";
			data = blogView(dir);
			break;
		case "/tags":
			//~ string dir = executeShell("cat /var/lib/dbus/machine-id").output[0..$-1] ~ "/auto";
			string dir = "auto/";
			data = listAllTags(dir);
			break;
		case "/tag":
			//~ string dir = executeShell("cat /var/lib/dbus/machine-id").output[0..$-1] ~ "/auto";
			string dir = "auto/";
			if ("t2" in cgi.get) {
				data = tagSearch(dir, cgi.get["t"], cgi.get["t2"]);
			}	else {
				data = tagSearch(dir, cgi.get["t"]);
			}
			break;
		case "/wikicreate":
			if (!exists(cgi.get["dir"])) {
				data = `Directory does not exist...<a href="/new">[Start Over]</a> <a href="/wikicreatedir?dir=` ~ cgi.get["dir"] ~ `&file=` ~ cgi.get["file"] ~ `">[Create Directory]</a>`;
			} else {
				string fn = cgi.get["dir"] ~ "/" ~ cgi.get["file"] ~ ".md";
				executeShell("geany -i " ~ fn);
				if (exists(fn)) {
					cgi.setResponseLocation("/wikiview?dir=" ~ cgi.get["dir"] ~ "&file=" ~ cgi.get["file"].encode);
				} else {
					data = "File not created...and I'm honestly not sure what you want to do at this point.";
				}
			}
			break;
		case "/wikicreatedir":
			cgi.get["dir"].mkdirRecurse();
			cgi.setResponseLocation(`/wikicreate?dir=` ~ cgi.get["dir"] ~ `&file=` ~ cgi.get["file"]);
			break;
		case "/wikiedit":
			executeShell("geany -i " ~ cgi.get["dir"] ~ "/" ~ cgi.get["file"] ~ ".md");
			cgi.setResponseLocation("/wikiview?dir=" ~ cgi.get["dir"] ~ "&file=" ~ cgi.get["file"]);
			break;
		case "/wikils":
			string files = "<h2>Files</h2><br>";
			string dirs = `<h3>Projects</h3>
<a href="wikils?dir=` ~ dirName(cgi.get["dir"]) ~ `">&#8632;</a><br>`;
			foreach (string name; dirEntries(cgi.get["dir"], SpanMode.depth).array.sort!"a > b") {
				if (isDir(name)) {
					dirs ~= `<a href="wikils?dir=` ~ name ~ `">` ~ name ~ "</a><br>\n";
				} else {
					if ( (extension(name) == ".md") && (dirName(name) == cgi.get["dir"]) ) {
						files ~= `<a href="wikiview?dir=` ~ dirName(name) ~ `&file=` ~ baseName(name).stripExtension.encode ~ `">` ~ baseName(name).stripExtension.decode ~ "</a><br>\n";
					}
				}
			}
			data = plaincss ~ files ~ dirs;
			break;
		case "/openfile":
			cgi.setResponseContentType(contentType(cgi.get["name"]));
			cgi.header(`Content-Disposition: attachment; filename="` ~ cgi.get["name"]);
			data = read(cgi.get["name"]).to!string;
			break;
		case "/attachedfile":
			if (!exists(cgi.get["thisdir"] ~ "/" ~ baseName(cgi.get["name"]))) {
				copy(cgi.get["name"], cgi.get["thisdir"] ~ "/" ~ baseName(cgi.get["name"]));
			}
			cgi.setResponseContentType(contentType(cgi.get["name"]));
			cgi.header(`Content-Disposition: attachment; filename="` ~ baseName(cgi.get["name"]));
			data = read(cgi.get["thisdir"] ~ "/" ~ baseName(cgi.get["name"])).to!string;
			break;
		case "/list":
			cgi.get["dir"].mkdirRecurse();
			if (!exists(cgi.get["dir"] ~ "/" ~ cgi.get["file"] ~ ".md")) {
				executeShell("geany -i " ~ cgi.get["dir"] ~ "/" ~ cgi.get["file"] ~ ".md");
			}
			data = compileList(cgi.get["dir"], cgi.get["file"]);
			break;
		case "/editlist":
			executeShell("geany -i " ~ cgi.get["dir"] ~ "/" ~ cgi.get["file"] ~ ".md");
			cgi.setResponseLocation("/list?dir=" ~ cgi.get["dir"] ~ "&file=" ~ cgi.get["file"]);
			break;
		case "/lists":
			switch(cgi.get["name"]) {
				case "projects":
					cgi.setResponseLocation("/list?dir=lists&file=projects");
					break;
				default:
					data = "You suck idiot";
					break;
			}
			break;
		case "/projects":
			cgi.setResponseLocation("/wikiview?dir=lists&file=projects");
			break;
		case "/someday":
			cgi.setResponseLocation("/wikiview?dir=lists&file=someday");
			break;
		case "/today":
			auto ct = Clock.currTime();
			cgi.setResponseLocation("/list?dir=tasks&file=tasks-" ~ ct.year.to!string ~ ct.month.to!string ~ ct.day.to!string);
			break;
		case "/help":
			cgi.setResponseLocation("/wikiview?dir=.&file=help");
			break;
		case "/tasks":
			string files = "<h2>Task Files</h2><br>";
			foreach (string name; dirEntries("tasks", SpanMode.depth)) {
				if (extension(name) == ".md") {
					files ~= `<a href="list?dir=tasks&file=` ~ baseName(name).stripExtension ~ `">` ~ baseName(name).stripExtension ~ "</a><br>\n";
				}
			}
			data = plaincss ~ files;
			break;
		case "/site.js":
			cgi.setResponseContentType("application/javascript");
			data = texme();
			break;
		case "/bookmark":
			std.file.append("bookmarks.html", "\n<br><a href=\"" ~ cgi.get["url"] ~ `">` ~ cgi.get["title"] ~ `</a>`);
			std.file.append("bookmarks.md", "\n- [" ~ cgi.get["title"] ~ `](` ~ cgi.get["url"] ~ `)  `);
			data = "Bookmarked!";
			break;
		case "/bookmarks":
			cgi.setResponseLocation("/wikiview?dir=.&file=bookmarks");
			break;
		case "/new":
			data = 
`<form action="/create" method="get">
  Directory:<br>
  <input type="text" name="dir">
  <br>
  Filename:<br>
  <input type="text" name="file">
  <br><br>
  <input type="submit" value="Submit">
</form><br><br>Current directories:<br><br>
`;
			foreach (string name; dirEntries("", SpanMode.depth)) {
				if (isDir(name)) {
					data ~= name ~ "<br>\n";
				}
			}
			break;
		case "/dash":
			cgi.setResponseLocation("/wikiview?dir=.&file=dashboard");
			break;
		case "/test":
			data = readableDT("2019-05-17T11:46:53.5180344");
			break;
		case "/push":
			data = repopush();
			break;
		case "/pull":
			data = repopull();
			break;
		case "/attachpull":
			data = attachpull();
			break;
		case "/attachpush":
			data = attachpush();
			break;
		default:
			data = "I don't know what that URL means";
	}
  cgi.write(data, true);
}
mixin GenericMain!app;

string simplecss() {
return `
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <meta http-equiv="Content-Style-Type" content="text/css" />
  <meta name="generator" content="pandoc" />
	<style type="text/css">
body {
    margin: auto;
    max-width: 960px;
    font-size: 120%;
    margin-top: 80px;
}

a {
    text-decoration: none;
}

pre > code {
  padding: .2rem .5rem;
  margin: 0 .2rem;
  font-size: 90%;
  white-space: nowrap;
  background: #F1F1F1;
  border: 1px solid #E1E1E1;
  border-radius: 4px; 
  display: block;
  padding: 1rem 1.5rem;
  white-space: pre; 
}

h1 {
	font-family: sans;
	font-size: 150%;
	border-bottom: 2px solid;
}

h2, h3 {
	font-family: sans;
	font-size: 125%;
}

</style>
<script src='https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.5/MathJax.js?config=TeX-MML-AM_CHTML' async></script>
</head>
<body>
`;
}

string wikiView(string fn, string dir, string file) {
	string ad = expandTilde("~" ~ attachdir);
	string[] tags = [];
	string f = readText(fn);
	if (f.startsWith("@")) {
		auto ind = f.indexOf("\n");
		tags = f[0..ind].split("@").filter!(`a != ""`).array;
		f = f[ind+1..$];
	}
	f = f.replace("](#", "](wikiview?dir=" ~ dir ~ "&file=");
	f = f.replace("](@", "](wikiviewalt?f=");
	f = f.replace("](file:", "](openfile?name=" ~ ad ~ "/");
	f = f.replace("](attach:", "](attachedfile?thisdir=" ~ dir ~ "&name=");
	string document;
	if (tags.length == 0) {
		document = simplecss() ~ f ~ "</body>";
	} else {
		string tagString = `Tags: <a href="tag?t=` ~ tags[0].strip ~ `">` ~ tags[0].strip ~ `</a> `;
		if (tags.length > 1) {
			foreach(tag; tags[1..$]) {
				string s = tag.strip;
				if (s != "") {
					// Change this to a tag index link when that's ready
					tagString ~= `| <a href="tag?t=` ~ tag.strip ~ `">` ~ tag.strip ~ `</a> `;
				}
			}
		}
		document = simplecss() ~ f ~ "\n\n" ~ tagString ~ "\n\n</body>";
	}
	std.file.write("__tmp.md", document);
	return executeShell("pandoc __tmp.md -t html --mathjax").output 
				  ~ "\n<br><br>&#9997; <a href=\"/wikiedit?dir=" ~ dir 
				  ~ "&file=" ~ file 
				  ~ `">Edit</a>     &#8593; <a href="wikils?dir=` 
				  ~ dir ~ "\">Index</a>" ~ ` &#8227; <a href="tags">Index of Tags</a> <a href="/openfile?name=` ~ dir ~ "/"  ~ file ~ 
						`.md">&#11123; Download</a>` ~ "\n\n";
}

string blogView(string dir) {
	string result = plaincss() ~ "\n<body>\n";
	foreach (string name; dirEntries(dir, SpanMode.depth).array.sort!("a > b")) {
		if (extension(name) == ".md") {
			string txt = readText(name);
			if (txt.length > 1000) {
				txt = txt[0..1000] ~ "...\n";
			}
			result ~= "<h2 style=\"color: brown;\">" ~ stripExtension(baseName(name)) ~ "</h2>\n\n" 
								~ compilePage(txt) ~ `<a href="opentext?name=` ~ name ~ `" target="_blank">Open</a>` ~ "\n<hr>\n";
		}
	}
	return result ~ "</body>";
}

string displayPage(string dir, string file) {
	string fn = dir ~ "/" ~ file ~ ".md";
	string an = dir ~ "/" ~ file ~ ".attach";
	string result;
	if (!exists(fn)) {
		return "File " ~ fn ~ " does not exist. " ~ `<a href="/create?dir=` ~ dir ~ `&file=` ~ file ~ `">Click here to create it.</a>`;
	} else {
		//~ result = tiddler(executeShell("pandoc " ~ fn ~ " -t html").output 
			//~ ~ "\n<br><br>&#9997; <a href=\"/edit?dir=" ~ dir ~ "&file=" ~ file ~ "\">Edit </a> 
			//~ &nbsp;&nbsp;&#128206; " ~ attLink(dir, file, "Attach") ~ "\n\n", fn);
		result = tiddler(executeShell("pandoc " ~ fn ~ " -t html").output 
			~ "\n<br><br>&#9997; <a href=\"/edit?dir=" ~ dir ~ "&file=" ~ file ~ `">Edit </a> <a href="ls?dir=` ~ dir ~ "\">Index</a>\n\n", fn);
		if (exists(an)) {
			std.file.write("__tmp.md", `# Attachments ` ~ attLink(dir, file, "⏻ ")
			~ `<a href="filemanager?dir=` ~ dir ~ `&file=` ~ file ~ `">&#10063;</a>` ~ "\n\n" ~ readText(an));
			result ~= tiddler(executeShell("pandoc __tmp.md -t html").output , "Attachments");
		}
	}
	return pageTop() ~ result ~ pageBottom(); 
}

string listAllTags(string dir) {
	string cmd = `cd ` ~ dir ~ `;grep -T -h -m 1 '.' *`;
	string lines = executeShell(cmd).output;
	string[] lineArray = lines.split("\n");
	string[string] aa;
	foreach(line; lineArray) {
		if (line.startsWith("@")) {
			foreach(tag; line.split("@")) {
				if (tag.strip != "") {
					aa[tag.strip] = "";
				}
			}
		}
	}
	string result = "<h1>List of Tags</h1>\n\n";
	foreach(tag; aa.keys.sort!"a < b") {
		result ~= "<br>\n<a href=\"tag?t=" ~ tag.strip ~ `">` ~ tag.strip ~ "</a>";
	}
	return plaincss() ~ result ~ "</body>";
}

string readableDT(string s) {
	DateTime dt = DateTime.fromISOExtString(s[0..19]);
	return dt.toSimpleString;
}

string tagSearch(string dir, string tag, string tag2="") {
	string cmd;
	string newtag = tag.replace(",", "/ && /@");
	newtag = newtag.replace("|", "/ || /@");
	if (tag2 == "") {
		cmd = `cd ` ~ dir ~ `;find . -type f -exec awk 'FNR>1 {nextfile} /@` ~ newtag ~ `/ { print FILENAME ; nextfile }' '{}' +`;
	} else {
		cmd = `cd ` ~ dir ~ `;find . -type f -exec awk 'FNR>1 {nextfile} /@` ~ tag ~ `/ && /@` ~ tag2 ~ `/ { print FILENAME ; nextfile }' '{}' +`;
	}
	string[] files = executeShell(cmd).output.split("\n").sort!"a > b".array;
	string result = "<h1>All Notes Tagged " ~ tag ~ " " ~ tag2 ~ "</h1>";
	foreach(file; files) {
		if (isFile(dir ~ "/" ~ file)) {
			string txt = readText(dir ~ "/" ~ file);
			string preview;
			if (txt.length < 200) {
				preview = txt;
			} else {
				preview = txt[0..200] ~ "...";
			}
			result ~= "<br>\n<a href=\"wikiview?dir=" ~ dir ~ "&file=" ~ baseName(file).stripExtension() ~ `">` ~ readableDT(baseName(file)) ~ "</a>"
				~ "<br><br><pre>" ~ preview ~ "</pre><br>";
		}
	}
	return plaincss() ~ result ~ `<br><br><a href="tags">Index of Tags</a>` ~ "\n</body>";
}

string createLink(string url, string text) {
	return `<a href="` ~ url ~ `">` ~ text ~ "</a>";
}

string dashboard() {
	string result = plaincss();
	result ~= "<h1>Dashboard</h1>\n";
	result ~= createLink("tags", "View all tags") ~ "\n<br>";
	result ~= createLink("help", "View help") ~ "\n<br>";
	result ~= "\n\n" ~ createLink("wikiedit/", "[Edit]");
	return result;
}

string contentType(string name) {
	switch(extension(name)) {
		case ".pdf":
			return "application/pdf";
		case ".eml":
			return "message/rfc822";
		case ".csv":
			return "text/csv";
		case ".txt":
			return "text/plain";
		case ".md":
			return "text/plain";
		case ".odt":
			return "application/vnd.oasis.opendocument.text";
		case ".ods":
			return "application/vnd.oasis.opendocument.spreadsheet";
		case ".png":
			return "image/png";
		case ".doc":
			return "application/msword";
		case ".docx":
			return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
		case ".xls":
			return "application/vnd.ms-excel";
		case ".xlsx":
			return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
		case ".mp3":
			return "audio/mpeg";
		case ".mpeg":
			return "audio/mpeg";
		default:
			return "text/plain";
	}
}		

/* Research pages should be wider than blog posts and such
 * That's all this does. */
string displayResearch(string dir, string file) {
	string fn = dir ~ "/" ~ file ~ ".md";
	string an = dir ~ "/" ~ file ~ ".attach";
	string result;
	if (!exists(fn)) {
		return "File " ~ fn ~ " does not exist. " ~ `<a href="/create?dir=` ~ dir ~ `&file=` ~ file ~ `">Click here to create it.</a>`;
	} else {
		result = tiddler(executeShell("pandoc " ~ fn ~ " -t html --mathjax").output 
			~ "\n<br><br>&#9997; <a href=\"/edit?dir=" ~ dir ~ "&file=" ~ file ~ "\">Edit </a>\n\n", fn);
		if (exists(an)) {
			std.file.write("__tmp.md", `# Attachments ` ~ attLink(dir, file, "⏻ ")
			~ `<a href="filemanager?dir=` ~ dir ~ `&file=` ~ file ~ `">&#10063;</a>` ~ "\n\n" ~ readText(an));
			result ~= tiddler(executeShell("pandoc __tmp.md -t html").output , "Attachments");
		}
	}
	/* Only change from pageTop is this */
	return researchTop() ~ result ~ pageBottom(); 
}

string buildPage(string fn, Cgi cgi) {
	string toc;
	string f = readFile(fn, cgi);
	string mainContent;
	foreach(line; f.split("\n")) {
		if (line.strip != "") {
			string[2] tmp = line.toHtml(cgi);
			toc ~= `<a href="#` ~ tmp[1] ~ `">` ~ tmp[1] ~ "</a><br>\n";
			mainContent ~= "\n" ~ tmp[0];
		}
	}
	string result = pageTop();
	/* If we're at root, we don't want to link to home cause we're already there */
	string tmp = toc ~ `<br><a href="edit?name=` ~ fn ~ `">&#8862; Change this page</a>`;
	if (cgi.cookies["dir"] != cgi.cookies["rootdir"]) {
		tmp ~= ` <a href="/home">♺ Home</a>`;
	}
	result ~= tiddler(tmp, "Contents");
	result ~= mainContent;
	result ~= pageBottom();
	return result;
}

string attLink(string dir, string file, string txt) {
	return `<a href="attachments?dir=` ~ dir ~ `&file=` ~ file ~ `">` ~ txt ~ `</a>`;
}

string spaces(int k) {
	string result = "";
	foreach(_; 0..k) {
		result ~= "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
	}
	return result;
}

string repopush() {
	string msg = executeShell(`git add --all :/;git commit -am "nm"; git pull; git push -u origin master`).output.replace("\n", "<br>");
	return "<h1>Push Repo</h1>\n\n" ~ simplecss() ~ msg ~ "<br><br>\n" ~ `<a href="dash">Return to Your Dashboard</a>`;
}

string repopull() {
	string msg = executeShell(`git add --all :/;git commit -am "nm"; git pull`).output.replace("\n", "<br>");
	return "<h1>Pull Repo</h1>\n\n" ~ simplecss() ~ msg ~ "<br><br>\n" ~ `<a href="dash">Return to Your Dashboard</a>`;
}

string attachpush() {
	string ad = expandTilde("~" ~ attachdir);
	string msg = executeShell(`cd ` ~ ad ~ `;git add --all :/;git commit -am "nm"; git pull; git push -u origin master`).output.replace("\n", "<br>");
	return "<h1>Push Repo</h1>\n\n" ~ simplecss() ~ msg ~ "<br><br>\n" ~ `<a href="dash">Return to Your Dashboard</a>`;
}

string attachpull() {
	string ad = expandTilde("~" ~ attachdir);
	string msg = executeShell(`cd ` ~ ad ~ `git add --all :/;git commit -am "nm"; git pull`).output.replace("\n", "<br>");
	return "<h1>Pull Repo</h1>\n\n" ~ simplecss() ~ msg ~ "<br><br>\n" ~ `<a href="dash">Return to Your Dashboard</a>`;
}

string plaincss() {
	return `
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <meta http-equiv="Content-Style-Type" content="text/css" />
  <meta name="generator" content="pandoc" />
<style type="text/css">
body {
    margin: auto;
    max-width: 800px;
    font-family: Ubuntu;
    font-size: 140%;
    margin-top: 20px;
    margin-bottom: 90px;
}

a {
	text-decoration: none;
}

h1 {
	font-size: 165%;
	line-height: 0.8em;
}

h2 {
	font-size: 110%;
	line-height: 0.5em;
	margin-bottom: 0px;
}
</style>
</head>
`;
}

string compilePage(string d, string f) {
	return executeShell("pandoc " ~ d ~ "/" ~ f ~ " -t html --mathjax").output;
}

string compilePage(string txt) {
	std.file.write("__tmp.md", txt);
	return executeShell("pandoc __tmp.md -t html --mathjax").output;
}

string plainPage(string d, string f) {
	string result = plaincss() ~ "\n<body>\n";
	result ~= compilePage(d, f);
	return result ~ "\n<\body>";
}

string compileList(string dir, string file) {
	string f = readText(dir ~ "/" ~ file ~ ".md");
	string[] lines = f.split("\n");
	string head = `<head>
<style type="text/css">
body {
    margin: auto;
    max-width: 800px;
    font-family: Ubuntu;
    font-size: 140%;
    margin-top: 20px;
    margin-bottom: 90px;
}

h1 {
	font-size: 165%;
	line-height: 0.8em;
}

a {
	text-decoration: none;
}

h2 {
	font-size: 110%;
	line-height: 0.5em;
	margin-bottom: 0px;
}
</style>
</head>
`;
	string content = "";
	string current = "";
	string toc = "<h1>Contents</h1>";
	int tocCount = 0;
	foreach(line; lines) {
		int indent = 0;
		string symbol = "&#9673;";
		if (line.startsWith("*")) {
			if (line.startsWith("***")) {
				indent = 2;
			} else if (line.startsWith("**")) {
				indent = 1; 
			}
			content ~= "<br>" ~ current;
			current = spaces(indent) ~ symbol ~ " " ~ line[indent+2..$];
		} else if (line.startsWith("-")) {
			symbol = "&#9675;";
			if (line.startsWith("---")) {
				indent = 2;
			} else if (line.startsWith("--")) {
				indent = 1;
			}
			content ~= "<br>" ~ current;
			current = spaces(indent) ~ symbol ~ " " ~ line[indent+2..$];
		} else if (line.startsWith("+")) {
			symbol = "&#10070;";
			if (line.startsWith("+++")) {
				indent = 2;
			} else if (line.startsWith("++")) {
				indent = 1;
			}
			content ~= "<br>" ~ current;
			current = spaces(indent) ~ symbol ~ " " ~ line[indent+2..$];
		} else if (line.startsWith("# ")) {
			toc ~= `<br><a href="#` ~ line[2..$] ~ `">` ~ line[2..$] ~ `</a>`;
			tocCount += 1;
			content ~= "<br>" ~ current;
			current = `<h1 id="` ~ line[2..$] ~ `">` ~ line[2..$] ~ "</h1>";
		} else if (line.startsWith("## ")) {
			content ~= "<br>" ~ current;
			current = `<h2 id="` ~ line[3..$] ~ `">` ~ line[3..$] ~ "</h2>";
		} else {
			current ~= "\n" ~ line;
		}
	}
	string result;
	if (tocCount > 3) {
		result = head ~ toc ~ content ~ "<br>" ~ current;
	} else {
		result = head ~ content ~ "<br>" ~ current;
	}
	result ~= "\n<br><br><a href=\"editlist?dir=" ~ dir ~ "&file=" ~ file ~ "\">&#9765; Edit</a>";
	return result;
}

string texme() {
	return `
! function() {
    "use strict";
    var t, d = {},
        i = {};
    d.setDefaultOptions = function() {
        i.renderOnLoad = !0, i.useMathJax = !0, i.protectMath = !0, i.style = "viewer", i.onRenderPage = void 0, i.commonmarkURL = "https://cdnjs.cloudflare.com/ajax/libs/commonmark/0.28.1/commonmark.min.js", i.MathJaxURL = "https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.5/MathJax.js?config=TeX-MML-AM_CHTML"
    };
    d.setOption = function(e, n) {
        i[e] = n
    };
    var e = function(e, n) {
        var t = window.document.createElement("script");
        t.src = e, t.onload = n, window.document.head.appendChild(t)
    };
    d.tokenType = {
        MARK: 0,
        MASK: 1
    }, d.tokenLiteral = {
        MASK: "::MASK::"
    };
    //~ #444
    //~ plain
    var m = {
        //~ viewer: ["body {", "  color: #333333;", "}", "h1, h2, h3, h4, h5, h6, h7 {", "  margin-bottom: 0.5em;", "}", "a:link, a:visited {", "  color: #0000e0;", "  text-decoration: underline;", "}", "a:hover, a:active {", "  color: #0000ff;", "  text-decoration: underline;", "}", "img {", "  max-width: 100%;", "}", "@media screen and (min-width: 40em) {", "  body {", "    background: #444;", "  }", "  main {", "    color: #333;", "    background: white;", "    padding: 5em 6em;", "    max-width: 40em;", "    margin: 1em auto;", "    box-shadow: 5px 5px 5px #222;", "  }", "}"].join("\n"),
        //~ plain: ["@media screen and (min-width: 40em) {", "  main {", "    color: #333;", "    max-width: 40em;",        
        viewer: ["@media screen and (min-width: 40em) {", 
        "  main {", "    color: #333;", "    max-width: 850px;", "    margin-left: auto;", 
        "    margin-right: auto;", "font-size: 18px;",
        "    line-height: 24px;", "font-family: sans-serif;", "  }", "}"].join("\n"),
        none: ""
    };
    d.tokenize = function(e) {
        for (var n, t, o = ["\\\\begin{.*}[\\s\\S]*?\\\\end{.*}", "\\\\\\[[\\s\\S]*?\\\\\\]", "\\\\\\([\\s\\S]*?\\\\\\)", "\\\\\\$", "\\$\\$(?:[^\\\\]|\\\\.)*?\\$\\$", "\\$(?:[^$\\\\]|\\\\.)+?\\$", d.tokenLiteral.MASK].join("|"), a = new RegExp(o, "g"), r = [], i = 0; null !== (n = a.exec(e));) n.index > i && (t = e.substring(i, n.index), r.push([d.tokenType.MARK, t])), r.push([d.tokenType.MASK, n[0]]), i = a.lastIndex;
        return t = e.substring(i), e.length > i && r.push([d.tokenType.MARK, t]), r
    }, d.mask = function(e) {
        var n, t, o, a = [],
            r = [];
        for (o = 0; o < e.length; o++) n = e[o][0], t = e[o][1], n === d.tokenType.MARK ? a.push(t) : (a.push(d.tokenLiteral.MASK), r.push(t));
        return {
            text: a.join(""),
            tokenValues: r
        }
    }, d.unmask = function(e, n) {
        var t = new RegExp(d.tokenLiteral.MASK, "g"),
            o = 0;
        return e.replace(t, function() {
            return n[o++]
        })
    }, d.renderCommonMark = function(e) {
        var n = (new t.Parser).parse(e);
        return (new t.HtmlRenderer).render(n)
    }, d.protectMathAndRenderCommonMark = function(e) {
        var n = d.tokenize(e),
            t = d.mask(n),
            o = d.renderCommonMark(t.text);
        return d.unmask(o, t.tokenValues)
    }, d.render = function(e) {
        return i.protectMath ? d.protectMathAndRenderCommonMark(e) : d.renderCommonMark(e)
    }, d.renderPage = function() {
        var e, n, t = window.document.getElementsByTagName("textarea"),
            o = window.document.createElement("main");
        0 < t.length ? (e = t[0].value.trim(), t[0].remove()) : (e = window.document.body.innerHTML.trim(), window.document.body.innerHTML = ""), void 0 !== window.document.title && "" !== window.document.title || (n = e.split("\n", 1)[0].replace(/^\s*#*\s*|\s*#*\s*$/g, ""), window.document.title = n), window.document.body.appendChild(o);
        var a = window.document.createElement("style"),
            r = m[i.style];
        a.appendChild(window.document.createTextNode(r)), window.document.head.appendChild(a), o.innerHTML = d.render(e), i.useMathJax && window.MathJax.Hub.Queue(["Typeset", window.MathJax.Hub, o]), void 0 !== i.onRenderPage && i.onRenderPage()
    }, d.main = function() {
        d.setDefaultOptions(), "undefined" != typeof window ? (! function() {
            var e;
            for (e in i) "undefined" != typeof window && void 0 !== window.texme && void 0 !== window.texme[e] && (i[e] = window.texme[e])
        }(), e(i.commonmarkURL, function() {
            t = window.commonmark
        }), i.useMathJax && (window.MathJax = {
            tex2jax: {
                inlineMath: [
                    ["$", "$"],
                    ["\\(", "\\)"]
                ],
                processEscapes: !0
            },
            TeX: {
                equationNumbers: {
                    autoNumber: "AMS"
                }
            },
            skipStartupTypeset: !0
        }, e(i.MathJaxURL)), i.renderOnLoad && (window.onload = d.renderPage), window.texme = d) : (t = require("commonmark"), module.exports = d)
    }, d.main()
}();
`;
}

/* If there is a divider |, the title is provided on that line
 * Otherwise, use the name of the file */
string[2] toHtml(string s, Cgi cgi) {
	if (s.strip == "") {
		return ["", ""];
	} else {
		string[] v = s.split("|");
		if (v.length == 1) {
			return [toTiddler(v[0].strip, v[0].strip, cgi), v[0].strip];
		} else {
			return [toTiddler(v[0].strip, v[1].strip, cgi), v[1].strip];
		}
	}
}

string readFile(string fn, Cgi cgi) {
	if ("dir" in cgi.cookies) {
		return readText(cgi.cookies["dir"] ~ fn);
	} else {
		return readText(fn);
	}
}

string taskTiddler(string f) {
	string result;
	foreach(task; ("\n" ~ f).split("\n[")) {
		if (task.startsWith(" ]")) {
			result ~= "☐ " ~ task[3..$] ~ "  \n  \n";
		} else if (task.startsWith("x]")) {
			result ~= "✔ " ~ task[3..$] ~ "  \n  \n";
		} else {
			result ~= task ~ "  \n  \n";
		}
	}
	return result;
}	

string toTiddler(string f, string h, Cgi cgi) {
	string content;
	string editText;
	if (extension(f) == ".tasks") {
		editText = "edit-tasks";
	} else {
		editText = "edit";
	}
	if (!std.file.exists(cgi.cookies["dir"] ~ f)) {
		content = `This file does not exist. <a href="` ~ editText ~ `?name=` ~ cgi.cookies["dir"] ~ f ~ `">Click here to create it.</a>`;
	} else {
		string mdfile = readFile(f, cgi);
		string tmp;
		if (extension(f) == ".tasks") {
			tmp = taskTiddler(mdfile);
		} else {
			foreach(line; mdfile.split("\n")) {
				if (line.startsWith("[ ]")) {
					tmp ~= "☐" ~ line[3..$] ~ "  \n";
				} else if (line.startsWith("[x]")) {
					/* Hide completed tasks*/
					tmp ~= "✔" ~ line[3..$] ~ "  \n";
				} else if (line.startsWith("{file:")) { // Does this still serve a purpose?
					auto ind = line.indexOf("|");
					auto ind2 = line.indexOf("}");
					tmp ~= `<a href="download?name=` ~ line[6..ind].strip ~ `">` ~ line[ind+1..ind2].strip ~ `</a>` ~ line[ind2+1..$] ~ "\n";
				} else {
					tmp ~= line ~ "\n";
				}
			}
		}
		string tmpfile = "__tmp" ~ extension(f);
		std.file.write(tmpfile, tmp);		
		content = executeShell("pandoc " ~ tmpfile ~ " -t html").output ~ "\n" ~ 
			`<br><br><a href="` ~ editText ~ `?name=` ~ f ~ `">Edit</a> <a href="/index">top</a>`;
	}
	return tiddler(content, h);
}	

// Second argument currently ignored
string tiddler(string content, string h="") {
	h = "";
	return 
	`<a name="` ~ h ~ `">
<div class="tc-tiddler-frame tc-tiddler-view-frame tc-tiddler-exists tc-tagged-Journal " data-tags="Journal" data-tiddler-title="` ~ h ~ `">
<div class="tc-tiddler-title">
` ~

/*

<div class="tc-titlebar">

<span class="tc-tiddler-controls">

<span class=" tc-reveal">

<button aria-label="more" class="tc-btn-invisible tc-btn-%24%3A%2Fcore%2Fui%2FButtons%2Fmore-tiddler-actions" title="More actions"></button>

<div class=" tc-reveal" hidden="true"></div>

</span>

<span class=" tc-reveal" hidden="true"></span>
<span class=" tc-reveal" hidden="true"></span>
<span class=" tc-reveal" hidden="true"></span>
<span class=" tc-reveal" hidden="true"></span>
<span class=" tc-reveal" hidden="true"></span>

<span class=" tc-reveal"><button aria-label="edit" class="tc-btn-invisible tc-btn-%24%3A%2Fcore%2Fui%2FButtons%2Fedit" title="Edit this tiddler"></button></span>

<span class=" tc-reveal" hidden="true"></span>
<span class=" tc-reveal" hidden="true"></span>
<span class=" tc-reveal" hidden="true"></span>
<span class=" tc-reveal" hidden="true"></span>
<span class=" tc-reveal" hidden="true"></span>

<span class=" tc-reveal">
<button aria-label="close" class="tc-btn-invisible tc-btn-%24%3A%2Fcore%2Fui%2FButtons%2Fclose" title="Close this tiddler"></button>
</span>

<span class=" tc-reveal" hidden="true"></span>
<span class=" tc-reveal" hidden="true"></span>
<span class=" tc-reveal" hidden="true"></span>
</span>

<span>

<span class="tc-tiddler-title-icon" style="fill:;"></span>

<h2 class="tc-title">
` ~ h ~ `
</h2>

</span>

</div> */

`<div class="tc-tiddler-info tc-popup-handle tc-reveal" hidden="true"></div>
</div><div class=" tc-reveal" hidden="true"></div>
<div class=" tc-reveal">
<div class="tc-subtitle">
<a class="tc-tiddlylink tc-tiddlylink-missing" href="#">

</a>
</div>
</div>
<div class=" tc-reveal">
<div class="tc-tags-wrapper"><span class="tc-tag-list-item">

<span class="tc-drop-down tc-reveal" hidden="true"></span></span></div>
</div>

<div class="tc-tiddler-body tc-reveal">`
~ content ~
`</div>



</div>


</a>`;
}

string pageBottom() {
	return `</section>
</body>
</html>`;
}

string pageTop() {
	return `<!doctype html>
<html>
<head><script src='https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.5/MathJax.js?config=TeX-MML-AM_CHTML' async></script>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
<meta name="generator" content="TiddlyWiki" />
<meta name="tiddlywiki-version" content="5.1.19" />
<meta name="format-detection" content="telephone=no">
<link id="faviconLink" rel="shortcut icon" href="favicon.ico">
<script src='https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.5/MathJax.js?config=TeX-MML-AM_CHTML' async></script>
<title>Title goes here</title>
<div id="styleArea">
<style data-tiddler-title="$:/boot/boot.css" data-tiddler-type="text/css" type="text/css">/*
Basic styles used before we boot up the parsing engine
*/

/*
Error message and password prompt
*/

.tc-error-form {
	font-family: sans-serif;
	color: #fff;
	z-index: 20000;
	position: fixed;
	background-color: rgb(255, 75, 75);
	border: 8px solid rgb(255, 0, 0);
	border-radius: 8px;
	width: 50%;
	margin-left: 25%;
	margin-top: 4em;
	padding: 0 2em 1em 2em;
}

.tc-error-form h1 {
	text-align: center;
}

.tc-error-prompt {
	text-align: center;
	color: #000;
}

.tc-error-message {
	overflow: auto;
	max-height: 40em;
	padding-right: 1em;
	margin: 1em 0;
	white-space: pre-line;
}

.tc-password-wrapper {
    font-family: sans-serif;
	z-index: 20000;
	position: fixed;
	text-align: center;
	width: 200px;
	top: 4em;
	left: 50%;
	margin-left: -144px; /* - width/2 - paddingHorz/2 - border */
	padding: 16px 16px 16px 16px;
	border-radius: 8px;
}

.tc-password-wrapper {
	color: #000;
	text-shadow: 0 1px 0 rgba(255, 255, 255, 0.5);
	background-color: rgb(197, 235, 183);
	border: 8px solid rgb(164, 197, 152);
}

.tc-password-wrapper form {
	text-align: left;
}

.tc-password-wrapper h1 {
	font-size: 16px;
	line-height: 20px;
	padding-bottom: 16px;
}

.tc-password-wrapper input {
	width: 100%;
}
</style>
</div>
<style type="text/css">

.tc-sidebar-header {
	text-shadow: 0 1px 0 rgba(255,255,255, 0.8);
}.tc-tiddler-info {
	
  -webkit-box-shadow: inset 1px 2px 3px rgba(0,0,0,0.1);
     -moz-box-shadow: inset 1px 2px 3px rgba(0,0,0,0.1);
          box-shadow: inset 1px 2px 3px rgba(0,0,0,0.1);

}@media screen {
	.tc-tiddler-frame {
		
  -webkit-box-shadow: 1px 1px 5px rgba(0, 0, 0, 0.3);
     -moz-box-shadow: 1px 1px 5px rgba(0, 0, 0, 0.3);
          box-shadow: 1px 1px 5px rgba(0, 0, 0, 0.3);

	}
}@media (max-width: 960px) {
	.tc-tiddler-frame {
		
  -webkit-box-shadow: none;
     -moz-box-shadow: none;
          box-shadow: none;

	}
}.tc-page-controls button svg, .tc-tiddler-controls button svg, .tc-topbar button svg {
	
  -webkit-transition: fill 150ms ease-in-out;
     -moz-transition: fill 150ms ease-in-out;
          transition: fill 150ms ease-in-out;

}.tc-tiddler-controls button.tc-selected,
.tc-page-controls button.tc-selected {
	
  -webkit-filter: drop-shadow(0px -1px 2px rgba(0,0,0,0.25));
     -moz-filter: drop-shadow(0px -1px 2px rgba(0,0,0,0.25));
          filter: drop-shadow(0px -1px 2px rgba(0,0,0,0.25));

}.tc-tiddler-frame input.tc-edit-texteditor {
	
  -webkit-box-shadow: inset 0 1px 8px rgba(0, 0, 0, 0.15);
     -moz-box-shadow: inset 0 1px 8px rgba(0, 0, 0, 0.15);
          box-shadow: inset 0 1px 8px rgba(0, 0, 0, 0.15);

}.tc-edit-tags {
	
  -webkit-box-shadow: inset 0 1px 8px rgba(0, 0, 0, 0.15);
     -moz-box-shadow: inset 0 1px 8px rgba(0, 0, 0, 0.15);
          box-shadow: inset 0 1px 8px rgba(0, 0, 0, 0.15);

}.tc-tiddler-frame .tc-edit-tags input.tc-edit-texteditor {
	
  -webkit-box-shadow: none;
     -moz-box-shadow: none;
          box-shadow: none;

	border: none;
	outline: none;
}textarea.tc-edit-texteditor {
	font-family: ;
}canvas.tc-edit-bitmapeditor  {
	
  -webkit-box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.5);
     -moz-box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.5);
          box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.5);

}.tc-drop-down {
	border-radius: 4px;
	
  -webkit-box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.5);
     -moz-box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.5);
          box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.5);

}.tc-block-dropdown {
	border-radius: 4px;
	
  -webkit-box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.5);
     -moz-box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.5);
          box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.5);

}.tc-modal {
	border-radius: 6px;
	
  -webkit-box-shadow: 0 3px 7px rgba(0,0,0,0.3);
     -moz-box-shadow: 0 3px 7px rgba(0,0,0,0.3);
          box-shadow: 0 3px 7px rgba(0,0,0,0.3);

}.tc-modal-footer {
	border-radius: 0 0 6px 6px;
	
  -webkit-box-shadow: inset 0 1px 0 #fff;
     -moz-box-shadow: inset 0 1px 0 #fff;
          box-shadow: inset 0 1px 0 #fff;
;
}.tc-alert {
	border-radius: 6px;
	
  -webkit-box-shadow: 0 3px 7px rgba(0,0,0,0.6);
     -moz-box-shadow: 0 3px 7px rgba(0,0,0,0.6);
          box-shadow: 0 3px 7px rgba(0,0,0,0.6);

}.tc-notification {
	border-radius: 6px;
	
  -webkit-box-shadow: 0 3px 7px rgba(0,0,0,0.3);
     -moz-box-shadow: 0 3px 7px rgba(0,0,0,0.3);
          box-shadow: 0 3px 7px rgba(0,0,0,0.3);

	text-shadow: 0 1px 0 rgba(255,255,255, 0.8);
}.tc-sidebar-lists .tc-tab-set .tc-tab-divider {
	border-top: none;
	height: 1px;
	
background-image: linear-gradient(left, rgba(0,0,0,0.15) 0%, rgba(0,0,0,0.0) 100%);
background-image: -o-linear-gradient(left, rgba(0,0,0,0.15) 0%, rgba(0,0,0,0.0) 100%);
background-image: -moz-linear-gradient(left, rgba(0,0,0,0.15) 0%, rgba(0,0,0,0.0) 100%);
background-image: -webkit-linear-gradient(left, rgba(0,0,0,0.15) 0%, rgba(0,0,0,0.0) 100%);
background-image: -ms-linear-gradient(left, rgba(0,0,0,0.15) 0%, rgba(0,0,0,0.0) 100%);

}.tc-more-sidebar > .tc-tab-set > .tc-tab-buttons > button {
	
background-image: linear-gradient(left, rgba(0,0,0,0.01) 0%, rgba(0,0,0,0.1) 100%);
background-image: -o-linear-gradient(left, rgba(0,0,0,0.01) 0%, rgba(0,0,0,0.1) 100%);
background-image: -moz-linear-gradient(left, rgba(0,0,0,0.01) 0%, rgba(0,0,0,0.1) 100%);
background-image: -webkit-linear-gradient(left, rgba(0,0,0,0.01) 0%, rgba(0,0,0,0.1) 100%);
background-image: -ms-linear-gradient(left, rgba(0,0,0,0.01) 0%, rgba(0,0,0,0.1) 100%);

}.tc-more-sidebar > .tc-tab-set > .tc-tab-buttons > button.tc-tab-selected {
	
background-image: linear-gradient(left, rgba(0,0,0,0.05) 0%, rgba(255,255,255,0.05) 100%);
background-image: -o-linear-gradient(left, rgba(0,0,0,0.05) 0%, rgba(255,255,255,0.05) 100%);
background-image: -moz-linear-gradient(left, rgba(0,0,0,0.05) 0%, rgba(255,255,255,0.05) 100%);
background-image: -webkit-linear-gradient(left, rgba(0,0,0,0.05) 0%, rgba(255,255,255,0.05) 100%);
background-image: -ms-linear-gradient(left, rgba(0,0,0,0.05) 0%, rgba(255,255,255,0.05) 100%);

}.tc-message-box img {
	
  -webkit-box-shadow: 1px 1px 3px rgba(0,0,0,0.5);
     -moz-box-shadow: 1px 1px 3px rgba(0,0,0,0.5);
          box-shadow: 1px 1px 3px rgba(0,0,0,0.5);

}.tc-plugin-info {
	
  -webkit-box-shadow: 1px 1px 3px rgba(0,0,0,0.5);
     -moz-box-shadow: 1px 1px 3px rgba(0,0,0,0.5);
          box-shadow: 1px 1px 3px rgba(0,0,0,0.5);

}


/*
** Start with the normalize CSS reset, and then belay some of its effects
*//*! normalize.css v3.0.0 | MIT License | git.io/normalize */

/**
 * 1. Set default font family to sans-serif.
 * 2. Prevent iOS text size adjust after orientation change, without disabling
 *    user zoom.
 */

html {
  font-family: sans-serif; /* 1 */
  -ms-text-size-adjust: 100%; /* 2 */
  -webkit-text-size-adjust: 100%; /* 2 */
}

/**
 * Remove default margin.
 */

body {
  margin: 0;
}

/* HTML5 display definitions
   ========================================================================== */

article,
aside,
details,
figcaption,
figure,
footer,
header,
hgroup,
main,
nav,
section,
summary {
  display: block;
}


audio,
canvas,
progress,
video {
  display: inline-block; /* 1 */
  vertical-align: baseline; /* 2 */
}


audio:not([controls]) {
  display: none;
  height: 0;
}


[hidden],
template {
  display: none;
}

/* Links
   ========================================================================== */

/**
 * Remove the gray background color from active links in IE 10.
 */

a {
  background: transparent;
}

/**
 * Improve readability when focused and also mouse hovered in all browsers.
 */

a:active,
a:hover {
  outline: 0;
}

/* Text-level semantics
   ========================================================================== */

/**
 * Address styling not present in IE 8/9, Safari 5, and Chrome.
 */

abbr[title] {
  border-bottom: 1px dotted;
}


b,
strong {
  font-weight: bold;
}

/**
 * Address styling not present in Safari 5 and Chrome.
 */

dfn {
  font-style: italic;
}


h1 {
  font-size: 2em;
  margin: 0.67em 0;
}

/**
 * Address styling not present in IE 8/9.
 */

mark {
  background: #ff0;
  color: #000;
}

/**
 * Address inconsistent and variable font size in all browsers.
 */

small {
  font-size: 80%;
}


sub,
sup {
  font-size: 75%;
  line-height: 0;
  position: relative;
  vertical-align: baseline;
}

sup {
  top: -0.5em;
}

sub {
  bottom: -0.25em;
}

/* Embedded content
   ========================================================================== */


img {
  border: 0;
}

/**
 * Correct overflow displayed oddly in IE 9.
 */

svg:not(:root) {
  overflow: hidden;
}

/* Grouping content
   ========================================================================== */

/**
 * Address margin not present in IE 8/9 and Safari 5.
 */

figure {
  margin: 1em 40px;
}

/**
 * Address differences between Firefox and other browsers.
 */

hr {
  -moz-box-sizing: content-box;
  box-sizing: content-box;
  height: 0;
}

/**
 * Contain overflow in all browsers.
 */

pre {
  overflow: auto;
}

code,
kbd,
pre,
samp {
  font-family: monospace, monospace;
  font-size: 1em;
}

/* Forms
   ========================================================================== */


/**
 * 1. Correct color not being inherited.
 *    Known issue: affects color of disabled elements.
 * 2. Correct font properties not being inherited.
 * 3. Address margins set differently in Firefox 4+, Safari 5, and Chrome.
 */

button,
input,
optgroup,
select,
textarea {
  color: inherit; /* 1 */
  font: inherit; /* 2 */
  margin: 0; /* 3 */
}


button {
  overflow: visible;
}


button,
select {
  text-transform: none;
}


button,
html input[type="button"], /* 1 */
input[type="reset"],
input[type="submit"] {
  -webkit-appearance: button; /* 2 */
  cursor: pointer; /* 3 */
}

/**
 * Re-set default cursor for disabled elements.
 */

button[disabled],
html input[disabled] {
  cursor: default;
}

/**
 * Remove inner padding and border in Firefox 4+.
 */

button::-moz-focus-inner,
input::-moz-focus-inner {
  border: 0;
  padding: 0;
}


input {
  line-height: normal;
}


input[type="checkbox"],
input[type="radio"] {
  box-sizing: border-box; /* 1 */
  padding: 0; /* 2 */
}

input[type="number"]::-webkit-inner-spin-button,
input[type="number"]::-webkit-outer-spin-button {
  height: auto;
}

/**
 * 1. Address appearance set to searchfield in Safari 5 and Chrome.
 * 2. Address box-sizing set to border-box in Safari 5 and Chrome
 *    (include -moz to future-proof).
 */

input[type="search"] {
  -webkit-appearance: textfield; /* 1 */
  -moz-box-sizing: content-box;
  -webkit-box-sizing: content-box; /* 2 */
  box-sizing: content-box;
}

/**
 * Remove inner padding and search cancel button in Safari and Chrome on OS X.
 * Safari (but not Chrome) clips the cancel button when the search input has
 * padding (and textfield appearance).
 */

input[type="search"]::-webkit-search-cancel-button,
input[type="search"]::-webkit-search-decoration {
  -webkit-appearance: none;
}

/**
 * Define consistent border, margin, and padding.
 */

fieldset {
  border: 1px solid #c0c0c0;
  margin: 0 2px;
  padding: 0.35em 0.625em 0.75em;
}

/**
 * 1. Correct color not being inherited in IE 8/9.
 * 2. Remove padding so people aren't caught out if they zero out fieldsets.
 */

legend {
  border: 0; /* 1 */
  padding: 0; /* 2 */
}

/**
 * Remove default vertical scrollbar in IE 8/9.
 */

textarea {
  overflow: auto;
}

/**
 * Don't inherit the font-weight (applied by a rule above).
 * NOTE: the default cannot safely be changed in Chrome and Safari on OS X.
 */

optgroup {
  font-weight: bold;
}

/* Tables
   ========================================================================== */

/**
 * Remove most spacing between table cells.
 */

table {
  border-collapse: collapse;
  border-spacing: 0;
}

td,
th {
  padding: 0;
}
*, input[type="search"] {
	box-sizing: border-box;
	-moz-box-sizing: border-box;
	-webkit-box-sizing: border-box;
}html button {
	line-height: 1.2;
	color: ;
	background: ;
	border-color: ;
}/*
** Basic element styles
*/html {
	font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
	text-rendering: optimizeLegibility; /* Enables kerning and ligatures etc. */
	-webkit-font-smoothing: antialiased;
	-moz-osx-font-smoothing: grayscale;
}html:-webkit-full-screen {
	background-color: #f4f4f4;
}body.tc-body {
	font-size: 14px;
	line-height: 20px;
	word-wrap: break-word;
	


	color: #333333;
	background-color: #f4f4f4;
	fill: #333333;
}h1, h2, h3, h4, h5, h6 {
	line-height: 1.2;
	font-weight: 300;
}pre {
	display: block;
	padding: 14px;
	margin-top: 1em;
	margin-bottom: 1em;
	word-break: normal;
	word-wrap: break-word;
	white-space: pre-wrap;
	background-color: #f5f5f5;
	border: 1px solid #cccccc;
	padding: 0 3px 2px;
	border-radius: 3px;
	font-family: "SFMono-Regular",Consolas,"Liberation Mono",Menlo,Courier,monospace;
}code {
	color: #dd1144;
	background-color: #f7f7f9;
	border: 1px solid #e1e1e8;
	white-space: pre-wrap;
	padding: 0 3px 2px;
	border-radius: 3px;
	font-family: "SFMono-Regular",Consolas,"Liberation Mono",Menlo,Courier,monospace;
}blockquote {
	border-left: 5px solid #bbb;
	margin-left: 25px;
	padding-left: 10px;
	quotes: "\201C""\201D""\2018""\2019";
}blockquote.tc-big-quote {
	font-family: Georgia, serif;
	position: relative;
	background: #f5f5f5;
	border-left: none;
	margin-left: 50px;
	margin-right: 50px;
	padding: 10px;
    border-radius: 8px;
}blockquote.tc-big-quote cite:before {
	content: "\2014 \2009";
}blockquote.tc-big-quote:before {
	font-family: Georgia, serif;
	color: #bbb;
	content: open-quote;
	font-size: 8em;
	line-height: 0.1em;
	margin-right: 0.25em;
	vertical-align: -0.4em;
	position: absolute;
    left: -50px;
    top: 42px;
}blockquote.tc-big-quote:after {
	font-family: Georgia, serif;
	color: #bbb;
	content: close-quote;
	font-size: 8em;
	line-height: 0.1em;
	margin-right: 0.25em;
	vertical-align: -0.4em;
	position: absolute;
    right: -80px;
    bottom: -20px;
}dl dt {
	font-weight: bold;
	margin-top: 6px;
}textarea,
input[type=text],
input[type=search],
input[type=""],
input:not([type]) {
	color: #333333;
	background: #ffffff;
}input[type="checkbox"] {
  vertical-align: middle;
}.tc-muted {
	color: #bbb;
}svg.tc-image-button {
	padding: 0px 1px 1px 0px;
}.tc-icon-wrapper > svg {
	width: 1em;
	height: 1em;
}kbd {
	display: inline-block;
	padding: 3px 5px;
	font-size: 0.8em;
	line-height: 1.2;
	color: #333333;
	vertical-align: middle;
	background-color: #ffffff;
	border: solid 1px #bbb;
	border-bottom-color: #bbb;
	border-radius: 3px;
	box-shadow: inset 0 -1px 0 #bbb;
}/*
Markdown likes putting code elements inside pre elements
*/
pre > code {
	padding: 0;
	border: none;
	background-color: inherit;
	color: inherit;
}table {
	border: 1px solid #dddddd;
	width: auto;
	max-width: 100%;
	caption-side: bottom;
	margin-top: 1em;
	margin-bottom: 1em;
}table th, table td {
	padding: 0 7px 0 7px;
	border-top: 1px solid #dddddd;
	border-left: 1px solid #dddddd;
}table thead tr td, table th {
	background-color: #f0f0f0;
	font-weight: bold;
}table tfoot tr td {
	background-color: #a8a8a8;
}.tc-csv-table {
	white-space: nowrap;
}.tc-tiddler-frame img,
.tc-tiddler-frame svg,
.tc-tiddler-frame canvas,
.tc-tiddler-frame embed,
.tc-tiddler-frame iframe {
	max-width: 100%;
}.tc-tiddler-body > embed,
.tc-tiddler-body > iframe {
	width: 100%;
	height: 600px;
}/*
** Links
*/button.tc-tiddlylink,
a.tc-tiddlylink {
	text-decoration: none;
	font-weight: 500;
	color: #5778d8;
	-webkit-user-select: inherit; /* Otherwise the draggable attribute makes links impossible to select */
}.tc-sidebar-lists a.tc-tiddlylink {
	color: #999999;
}.tc-sidebar-lists a.tc-tiddlylink:hover {
	color: #444444;
}button.tc-tiddlylink:hover,
a.tc-tiddlylink:hover {
	text-decoration: underline;
}a.tc-tiddlylink-resolves {
}a.tc-tiddlylink-shadow {
	font-weight: bold;
}a.tc-tiddlylink-shadow.tc-tiddlylink-resolves {
	font-weight: normal;
}a.tc-tiddlylink-missing {
	font-style: italic;
}a.tc-tiddlylink-external {
	text-decoration: underline;
	color: #0000ee;
	background-color: inherit;
}a.tc-tiddlylink-external:visited {
	color: #0000aa;
	background-color: inherit;
}a.tc-tiddlylink-external:hover {
	color: inherit;
	background-color: inherit;
}/*
** Drag and drop styles
*/.tc-tiddler-dragger {
	position: relative;
	z-index: -10000;
}.tc-tiddler-dragger-inner {
	position: absolute;
	top: -1000px;
	left: -1000px;
	display: inline-block;
	padding: 8px 20px;
	font-size: 16.9px;
	font-weight: bold;
	line-height: 20px;
	color: #ffffff;
	text-shadow: 0 1px 0 rgba(0, 0, 0, 1);
	white-space: nowrap;
	vertical-align: baseline;
	background-color: #333333;
	border-radius: 20px;
}.tc-tiddler-dragger-cover {
	position: absolute;
	background-color: #f4f4f4;
}.tc-dropzone {
	position: relative;
}.tc-dropzone.tc-dragover:before {
	z-index: 10000;
	display: block;
	position: fixed;
	top: 0;
	left: 0;
	right: 0;
	background: rgba(0,200,0,0.7);
	text-align: center;
	content: "Drop here (or use the 'Escape' key to cancel)";
}.tc-droppable > .tc-droppable-placeholder {
	display: none;
}.tc-droppable.tc-dragover > .tc-droppable-placeholder {
	display: block;
	border: 2px dashed rgba(0,200,0,0.7);
}.tc-draggable {
	cursor: move;
}/*
** Plugin reload warning
*/.tc-plugin-reload-warning {
	z-index: 1000;
	display: block;
	position: fixed;
	top: 0;
	left: 0;
	right: 0;
	background: #ffe476;
	text-align: center;
}/*
** Buttons
*/button svg, button img, label svg, label img {
	vertical-align: middle;
}.tc-btn-invisible {
	padding: 0;
	margin: 0;
	background: none;
	border: none;
    cursor: pointer;
}.tc-btn-boxed {
	font-size: 0.6em;
	padding: 0.2em;
	margin: 1px;
	background: none;
	border: 1px solid #cccccc;
	border-radius: 0.25em;
}html body.tc-body .tc-btn-boxed svg {
	font-size: 1.6666em;
}.tc-btn-boxed:hover {
	background: #bbb;
	color: #ffffff;
}html body.tc-body .tc-btn-boxed:hover svg {
	fill: #ffffff;
}.tc-btn-rounded {
	font-size: 0.5em;
	line-height: 2;
	padding: 0em 0.3em 0.2em 0.4em;
	margin: 1px;
	border: 1px solid #bbb;
	background: #bbb;
	color: #ffffff;
	border-radius: 2em;
}html body.tc-body .tc-btn-rounded svg {
	font-size: 1.6666em;
	fill: #ffffff;
}.tc-btn-rounded:hover {
	border: 1px solid #bbb;
	background: #ffffff;
	color: #bbb;
}html body.tc-body .tc-btn-rounded:hover svg {
	fill: #bbb;
}.tc-btn-icon svg {
	height: 1em;
	width: 1em;
	fill: #bbb;
}.tc-btn-text {
	padding: 0;
	margin: 0;
}/* used for documentation "fake" buttons */
.tc-btn-standard {
	line-height: 1.8;
	color: #667;
	background-color: #e0e0e0;
	border: 1px solid #888;
	padding: 2px 1px 2px 1px;
	margin: 1px 4px 1px 4px;
}.tc-btn-big-green {
	display: inline-block;
	padding: 8px;
	margin: 4px 8px 4px 8px;
	background: #34c734;
	color: #ffffff;
	fill: #ffffff;
	border: none;
	font-size: 1.2em;
	line-height: 1.4em;
	text-decoration: none;
}.tc-btn-big-green svg,
.tc-btn-big-green img {
	height: 2em;
	width: 2em;
	vertical-align: middle;
	fill: #ffffff;
}.tc-sidebar-lists input {
	color: #333333;
}.tc-sidebar-lists button {
	color: #333333;
	fill: #333333;
}.tc-sidebar-lists button.tc-btn-mini {
	color: #c0c0c0;
}.tc-sidebar-lists button.tc-btn-mini:hover {
	color: #444444;
}button svg.tc-image-button, button .tc-image-button img {
	height: 1em;
	width: 1em;
}.tc-unfold-banner {
	position: absolute;
	padding: 0;
	margin: 0;
	background: none;
	border: none;
	width: 100%;
	width: calc(100% + 2px);
	margin-left: -43px;
	text-align: center;
	border-top: 2px solid #f8f8f8;
	margin-top: 4px;
}.tc-unfold-banner:hover {
	background: #f8f8f8;
	border-top: 2px solid #dddddd;
}.tc-unfold-banner svg, .tc-fold-banner svg {
	height: 0.75em;
	fill: #cccccc;
}.tc-unfold-banner:hover svg, .tc-fold-banner:hover svg {
	fill: #888888;
}.tc-fold-banner {
	position: absolute;
	padding: 0;
	margin: 0;
	background: none;
	border: none;
	width: 23px;
	text-align: center;
	margin-left: -35px;
	top: 6px;
	bottom: 6px;
}.tc-fold-banner:hover {
	background: #f8f8f8;
}@media (max-width: 960px) {.tc-unfold-banner {
		position: static;
		width: calc(100% + 59px);
	}.tc-fold-banner {
		width: 16px;
		margin-left: -16px;
		font-size: 0.75em;
	}}/*
** Tags and missing tiddlers
*/.tc-tag-list-item {
	position: relative;
	display: inline-block;
	margin-right: 7px;
}.tc-tags-wrapper {
	margin: 4px 0 14px 0;
}.tc-missing-tiddler-label {
	font-style: italic;
	font-weight: normal;
	display: inline-block;
	font-size: 11.844px;
	line-height: 14px;
	white-space: nowrap;
	vertical-align: baseline;
}button.tc-tag-label, span.tc-tag-label {
	display: inline-block;
	padding: 0.16em 0.7em;
	font-size: 0.9em;
	font-weight: 400;
	line-height: 1.2em;
	color: #ffffff;
	white-space: nowrap;
	vertical-align: baseline;
	background-color: #ec6;
	border-radius: 1em;
}.tc-untagged-separator {
	width: 10em;
	left: 0;
	margin-left: 0;
	border: 0;
	height: 1px;
	background: #d8d8d8;
}button.tc-untagged-label {
	background-color: #999999;
}.tc-tag-label svg, .tc-tag-label img {
	height: 1em;
	width: 1em;
	vertical-align: text-bottom;
}.tc-tag-manager-table .tc-tag-label {
	white-space: normal;
}.tc-tag-manager-tag {
	width: 100%;
}button.tc-btn-invisible.tc-remove-tag-button {
	outline: none;
}/*
** Page layout
*/.tc-topbar {
	position: fixed;
	z-index: 1200;
}.tc-topbar-left {
	left: 29px;
	top: 5px;
}.tc-topbar-right {
	top: 5px;
	right: 29px;
}.tc-topbar button {
	padding: 8px;
}.tc-topbar svg {
	fill: #bbb;
}.tc-topbar button:hover svg {
	fill: #333333;
}.tc-sidebar-header {
	color: #acacac;
	fill: #acacac;
}.tc-sidebar-header .tc-title a.tc-tiddlylink-resolves {
	font-weight: 300;
}.tc-sidebar-header .tc-sidebar-lists p {
	margin-top: 3px;
	margin-bottom: 3px;
}.tc-sidebar-header .tc-missing-tiddler-label {
	color: #acacac;
}.tc-advanced-search input {
	width: 60%;
}.tc-search a svg {
	width: 1.2em;
	height: 1.2em;
	vertical-align: middle;
}.tc-page-controls {
	margin-top: 14px;
	font-size: 1.5em;
}.tc-page-controls .tc-drop-down {
  font-size: 1rem;
}.tc-page-controls button {
	margin-right: 0.5em;
}.tc-page-controls a.tc-tiddlylink:hover {
	text-decoration: none;
}.tc-page-controls img {
	width: 1em;
}.tc-page-controls svg {
	fill: #aaaaaa;
}.tc-page-controls button:hover svg, .tc-page-controls a:hover svg {
	fill: #000000;
}.tc-menu-list-item {
	white-space: nowrap;
}.tc-menu-list-count {
	font-weight: bold;
}.tc-menu-list-subitem {
	padding-left: 7px;
}.tc-story-river {
	position: relative;
}@media (max-width: 960px) {.tc-sidebar-header {
		padding: 14px;
		min-height: 32px;
		margin-top: 0px;
	}.tc-story-river {
		position: relative;
		padding: 0;
	}
}@media (min-width: 960px) {.tc-message-box {
		margin: 21px -21px 21px -21px;
	}.tc-sidebar-scrollable {
		position: fixed;
		top: 0px;
		left: 770px;
		bottom: 0;
		right: 0;
		overflow-y: auto;
		overflow-x: auto;
		-webkit-overflow-scrolling: touch;
		margin: 0 0 0 -42px;
		padding: 71px 0 28px 42px;
	}html[dir="rtl"] .tc-sidebar-scrollable {
		left: auto;
		right: 770px;
	}.tc-story-river {
		position: relative;
		left: 0px;
		top: 0px;
		width: 770px;
		padding: 42px 42px 42px 42px;
	}}@media print {body.tc-body {
		background-color: transparent;
	}.tc-sidebar-header, .tc-topbar {
		display: none;
	}.tc-story-river {
		margin: 0;
		padding: 0;
	}.tc-story-river .tc-tiddler-frame {
		margin: 0;
		border: none;
		padding: 0;
	}
}/*
** Tiddler styles
*/.tc-tiddler-frame {
	position: relative;
	margin-bottom: 28px;
	background-color: #ffffff;
	border: 1px solid #ffffff;
}
.tc-tiddler-info {
	padding: 14px 42px 14px 42px;
	background-color: #f8f8f8;
	border-top: 1px solid #dddddd;
	border-bottom: 1px solid #dddddd;
}.tc-tiddler-info p {
	margin-top: 3px;
	margin-bottom: 3px;
}.tc-tiddler-info .tc-tab-buttons button.tc-tab-selected {
	background-color: #f8f8f8;
	border-bottom: 1px solid #f8f8f8;
}.tc-view-field-table {
	width: 100%;
}.tc-view-field-name {
	width: 1%; /* Makes this column be as narrow as possible */
	text-align: right;
	font-style: italic;
	font-weight: 200;
}.tc-view-field-value {
}@media (max-width: 960px) {
	.tc-tiddler-frame {
		padding: 14px 14px 14px 14px;
	}.tc-tiddler-info {
		margin: 0 -14px 0 -14px;
	}
}@media (min-width: 960px) {
	.tc-tiddler-frame {
		padding: 28px 42px 42px 42px;
		width: 686px;
		border-radius: 2px;
	}.tc-tiddler-info {
		margin: 0 -42px 0 -42px;
	}
}.tc-site-title,
.tc-titlebar {
	font-weight: 300;
	font-size: 2.35em;
	line-height: 1.2em;
	color: #182955;
	margin: 0;
}.tc-site-title {
	color: #182955;
}.tc-tiddler-title-icon {
	vertical-align: middle;
}.tc-system-title-prefix {
	color: #bbb;
}.tc-titlebar h2 {
	font-size: 1em;
	display: inline;
}.tc-titlebar img {
	height: 1em;
}.tc-subtitle {
	font-size: 0.9em;
	color: #c0c0c0;
	font-weight: 300;
}.tc-tiddler-missing .tc-title {
  font-style: italic;
  font-weight: normal;
}.tc-tiddler-frame .tc-tiddler-controls {
	float: right;
}.tc-tiddler-controls .tc-drop-down {
	font-size: 0.6em;
}.tc-tiddler-controls .tc-drop-down .tc-drop-down {
	font-size: 1em;
}.tc-tiddler-controls > span > button,
.tc-tiddler-controls > span > span > button,
.tc-tiddler-controls > span > span > span > button {
	vertical-align: baseline;
	margin-left:5px;
}.tc-tiddler-controls button svg, .tc-tiddler-controls button img,
.tc-search button svg, .tc-search a svg {
	fill: #cccccc;
}.tc-tiddler-controls button svg, .tc-tiddler-controls button img {
	height: 0.75em;
}.tc-search button svg, .tc-search a svg {
    height: 1.2em;
    width: 1.2em;
    margin: 0 0.25em;
}.tc-tiddler-controls button.tc-selected svg,
.tc-page-controls button.tc-selected svg  {
	fill: #444444;
}.tc-tiddler-controls button.tc-btn-invisible:hover svg,
.tc-search button:hover svg, .tc-search a:hover svg {
	fill: #888888;
}@media print {
	.tc-tiddler-controls {
		display: none;
	}
}.tc-tiddler-help { /* Help prompts within tiddler template */
	color: #bbb;
	margin-top: 14px;
}.tc-tiddler-help a.tc-tiddlylink {
	color: #888888;
}.tc-tiddler-frame .tc-edit-texteditor {
	width: 100%;
	margin: 4px 0 4px 0;
}.tc-tiddler-frame input.tc-edit-texteditor,
.tc-tiddler-frame textarea.tc-edit-texteditor,
.tc-tiddler-frame iframe.tc-edit-texteditor {
	padding: 3px 3px 3px 3px;
	border: 1px solid #cccccc;
	background-color: #f8f8f8;
	line-height: 1.3em;
	-webkit-appearance: none;
	font-family: ;
}.tc-tiddler-frame .tc-binary-warning {
	width: 100%;
	height: 5em;
	text-align: center;
	padding: 3em 3em 6em 3em;
	background: #ffe476;
	border: 1px solid #b99e2f;
}canvas.tc-edit-bitmapeditor  {
	border: 6px solid #ffffff;
	cursor: crosshair;
	-moz-user-select: none;
	-webkit-user-select: none;
	-ms-user-select: none;
	margin-top: 6px;
	margin-bottom: 6px;
}.tc-edit-bitmapeditor-width {
	display: block;
}.tc-edit-bitmapeditor-height {
	display: block;
}.tc-tiddler-body {
	clear: both;
}.tc-tiddler-frame .tc-tiddler-body {
/** Changed **/
	font-size: 22px;
	line-height: 28px;
}.tc-titlebar, .tc-tiddler-edit-title {
	overflow: hidden; /* https://github.com/Jermolene/TiddlyWiki5/issues/282 */
}html body.tc-body.tc-single-tiddler-window {
	margin: 1em;
	background: #ffffff;
}.tc-single-tiddler-window img,
.tc-single-tiddler-window svg,
.tc-single-tiddler-window canvas,
.tc-single-tiddler-window embed,
.tc-single-tiddler-window iframe {
	max-width: 100%;
}/*
** Editor
*/.tc-editor-toolbar {
	margin-top: 8px;
}.tc-editor-toolbar button {
	vertical-align: middle;
	background-color: #cccccc;
	fill: #444444;
	border-radius: 4px;
	padding: 3px;
	margin: 2px 0 2px 4px;
}.tc-editor-toolbar button.tc-text-editor-toolbar-item-adjunct {
	margin-left: 1px;
	width: 1em;
	border-radius: 8px;
}.tc-editor-toolbar button.tc-text-editor-toolbar-item-start-group {
	margin-left: 11px;
}.tc-editor-toolbar button.tc-selected {
	background-color: #5778d8;
}.tc-editor-toolbar button svg {
	width: 1.6em;
	height: 1.2em;
}.tc-editor-toolbar button:hover {
	background-color: #444444;
	fill: #ffffff;
	color: #ffffff;
}.tc-editor-toolbar .tc-text-editor-toolbar-more {
	white-space: normal;
}.tc-editor-toolbar .tc-text-editor-toolbar-more button {
	display: inline-block;
	padding: 3px;
	width: auto;
}.tc-editor-toolbar .tc-search-results {
	padding: 0;
}/*
** Adjustments for fluid-fixed mode
*/@media (min-width: 960px) {}/*
** Toolbar buttons
*/.tc-page-controls svg.tc-image-new-button {
  fill: ;
}.tc-page-controls svg.tc-image-options-button {
  fill: ;
}.tc-page-controls svg.tc-image-save-button {
  fill: ;
}.tc-tiddler-controls button svg.tc-image-info-button {
  fill: ;
}.tc-tiddler-controls button svg.tc-image-edit-button {
  fill: ;
}.tc-tiddler-controls button svg.tc-image-close-button {
  fill: ;
}.tc-tiddler-controls button svg.tc-image-delete-button {
  fill: ;
}.tc-tiddler-controls button svg.tc-image-cancel-button {
  fill: ;
}.tc-tiddler-controls button svg.tc-image-done-button {
  fill: ;
}/*
** Tiddler edit mode
*/.tc-tiddler-edit-frame em.tc-edit {
	color: #bbb;
	font-style: normal;
}.tc-edit-type-dropdown a.tc-tiddlylink-missing {
	font-style: normal;
}.tc-edit-tags {
	border: 1px solid #cccccc;
	padding: 4px 8px 4px 8px;
}.tc-edit-add-tag {
	display: inline-block;
}.tc-edit-add-tag .tc-add-tag-name input {
	width: 50%;
}.tc-edit-add-tag .tc-keyboard {
	display:inline;
}.tc-edit-tags .tc-tag-label {
	display: inline-block;
}.tc-edit-tags-list {
	margin: 14px 0 14px 0;
}.tc-remove-tag-button {
	padding-left: 4px;
}.tc-tiddler-preview {
	overflow: auto;
}.tc-tiddler-preview-preview {
	float: right;
	width: 49%;
	border: 1px solid #cccccc;
	margin: 4px 0 3px 3px;
	padding: 3px 3px 3px 3px;
}.tc-tiddler-frame .tc-tiddler-preview .tc-edit-texteditor {
	width: 49%;
}.tc-tiddler-frame .tc-tiddler-preview canvas.tc-edit-bitmapeditor {
	max-width: 49%;
}.tc-edit-fields {
	width: 100%;
}.tc-edit-fields table, .tc-edit-fields tr, .tc-edit-fields td {
	border: none;
	padding: 4px;
}.tc-edit-fields > tbody > .tc-edit-field:nth-child(odd) {
	background-color: #f0f4f0;
}.tc-edit-fields > tbody > .tc-edit-field:nth-child(even) {
	background-color: #e0e8e0;
}.tc-edit-field-name {
	text-align: right;
}.tc-edit-field-value input {
	width: 100%;
}.tc-edit-field-remove {
}.tc-edit-field-remove svg {
	height: 1em;
	width: 1em;
	fill: #bbb;
	vertical-align: middle;
}.tc-edit-field-add-name {
	display: inline-block;
	width: 15%;
}.tc-edit-field-add-value {
	display: inline-block;
	width: 40%;
}.tc-edit-field-add-button {
	display: inline-block;
	width: 10%;
}/*
** Storyview Classes
*/.tc-storyview-zoomin-tiddler {
	position: absolute;
	display: block;
	width: 100%;
}@media (min-width: 960px) {.tc-storyview-zoomin-tiddler {
		width: calc(100% - 84px);
	}}/*
** Dropdowns
*/.tc-btn-dropdown {
	text-align: left;
}.tc-btn-dropdown svg, .tc-btn-dropdown img {
	height: 1em;
	width: 1em;
	fill: #bbb;
}.tc-drop-down-wrapper {
	position: relative;
}.tc-drop-down {
	min-width: 380px;
	border: 1px solid #bbb;
	background-color: #ffffff;
	padding: 7px 0 7px 0;
	margin: 4px 0 0 0;
	white-space: nowrap;
	text-shadow: none;
	line-height: 1.4;
}.tc-drop-down .tc-drop-down {
	margin-left: 14px;
}.tc-drop-down button svg, .tc-drop-down a svg  {
	fill: #333333;
}.tc-drop-down button.tc-btn-invisible:hover svg {
	fill: #333333;
}.tc-drop-down p {
	padding: 0 14px 0 14px;
}.tc-drop-down svg {
	width: 1em;
	height: 1em;
}.tc-drop-down img {
	width: 1em;
}.tc-drop-down a, .tc-drop-down button {
	display: block;
	padding: 0 14px 0 14px;
	width: 100%;
	text-align: left;
	color: #333333;
	line-height: 1.4;
}.tc-drop-down .tc-tab-set .tc-tab-buttons button {
	display: inline-block;
    width: auto;
    margin-bottom: 0px;
    border-bottom-left-radius: 0;
    border-bottom-right-radius: 0;
}.tc-drop-down .tc-prompt {
	padding: 0 14px;
}.tc-drop-down .tc-chooser {
	border: none;
}.tc-drop-down .tc-chooser .tc-swatches-horiz {
	font-size: 0.4em;
	padding-left: 1.2em;
}.tc-drop-down .tc-file-input-wrapper {
	width: 100%;
}.tc-drop-down .tc-file-input-wrapper button {
	color: #333333;
}.tc-drop-down a:hover, .tc-drop-down button:hover, .tc-drop-down .tc-file-input-wrapper:hover button {
	color: #ffffff;
	background-color: #5778d8;
	text-decoration: none;
}.tc-drop-down .tc-tab-buttons button {
	background-color: #ececec;
}.tc-drop-down .tc-tab-buttons button.tc-tab-selected {
	background-color: #fff;
	border-bottom: 1px solid #fff;
}.tc-drop-down-bullet {
	display: inline-block;
	width: 0.5em;
}.tc-drop-down .tc-tab-contents a {
	padding: 0 0.5em 0 0.5em;
}.tc-block-dropdown-wrapper {
	position: relative;
}.tc-block-dropdown {
	position: absolute;
	min-width: 220px;
	border: 1px solid #bbb;
	background-color: #ffffff;
	padding: 7px 0;
	margin: 4px 0 0 0;
	white-space: nowrap;
	z-index: 1000;
	text-shadow: none;
}.tc-block-dropdown.tc-search-drop-down {
	margin-left: -12px;
}.tc-block-dropdown a {
	display: block;
	padding: 4px 14px 4px 14px;
}.tc-block-dropdown.tc-search-drop-down a {
	display: block;
	padding: 0px 10px 0px 10px;
}.tc-drop-down .tc-dropdown-item-plain,
.tc-block-dropdown .tc-dropdown-item-plain {
	padding: 4px 14px 4px 7px;
}.tc-drop-down .tc-dropdown-item,
.tc-block-dropdown .tc-dropdown-item {
	padding: 4px 14px 4px 7px;
	color: #bbb;
}.tc-block-dropdown a:hover {
	color: #ffffff;
	background-color: #5778d8;
	text-decoration: none;
}.tc-search-results {
	padding: 0 7px 0 7px;
}.tc-image-chooser, .tc-colour-chooser {
	white-space: normal;
}.tc-image-chooser a,
.tc-colour-chooser a {
	display: inline-block;
	vertical-align: top;
	text-align: center;
	position: relative;
}.tc-image-chooser a {
	border: 1px solid #bbb;
	padding: 2px;
	margin: 2px;
	width: 4em;
	height: 4em;
}.tc-colour-chooser a {
	padding: 3px;
	width: 2em;
	height: 2em;
	vertical-align: middle;
}.tc-image-chooser a:hover,
.tc-colour-chooser a:hover {
	background: #5778d8;
	padding: 0px;
	border: 3px solid #5778d8;
}.tc-image-chooser a svg,
.tc-image-chooser a img {
	display: inline-block;
	width: auto;
	height: auto;
	max-width: 3.5em;
	max-height: 3.5em;
	position: absolute;
	top: 0;
	bottom: 0;
	left: 0;
	right: 0;
	margin: auto;
}/*
** Modals
*/.tc-modal-wrapper {
	position: fixed;
	overflow: auto;
	overflow-y: scroll;
	top: 0;
	right: 0;
	bottom: 0;
	left: 0;
	z-index: 900;
}.tc-modal-backdrop {
	position: fixed;
	top: 0;
	right: 0;
	bottom: 0;
	left: 0;
	z-index: 1000;
	background-color: #333333;
}.tc-modal {
	z-index: 1100;
	background-color: #ffffff;
	border: 1px solid #999999;
}@media (max-width: 55em) {
	.tc-modal {
		position: fixed;
		top: 1em;
		left: 1em;
		right: 1em;
	}.tc-modal-body {
		overflow-y: auto;
		max-height: 400px;
		max-height: 60vh;
	}
}@media (min-width: 55em) {
	.tc-modal {
		position: fixed;
		top: 2em;
		left: 25%;
		width: 50%;
	}.tc-modal-body {
		overflow-y: auto;
		max-height: 400px;
		max-height: 60vh;
	}
}.tc-modal-header {
	padding: 9px 15px;
	border-bottom: 1px solid #eeeeee;
}.tc-modal-header h3 {
	margin: 0;
	line-height: 30px;
}.tc-modal-header img, .tc-modal-header svg {
	width: 1em;
	height: 1em;
}.tc-modal-body {
	padding: 15px;
}.tc-modal-footer {
	padding: 14px 15px 15px;
	margin-bottom: 0;
	text-align: right;
	background-color: #f5f5f5;
	border-top: 1px solid #dddddd;
}/*
** Notifications
*/.tc-notification {
	position: fixed;
	top: 14px;
	right: 42px;
	z-index: 1300;
	max-width: 280px;
	padding: 0 14px 0 14px;
	background-color: #ffffdd;
	border: 1px solid #999999;
}/*
** Tabs
*/.tc-tab-set.tc-vertical {
	display: -webkit-flex;
	display: flex;
}.tc-tab-buttons {
	font-size: 0.85em;
	padding-top: 1em;
	margin-bottom: -2px;
}.tc-tab-buttons.tc-vertical  {
	z-index: 100;
	display: block;
	padding-top: 14px;
	vertical-align: top;
	text-align: right;
	margin-bottom: inherit;
	margin-right: -1px;
	max-width: 33%;
	-webkit-flex: 0 0 auto;
	flex: 0 0 auto;
}.tc-tab-buttons button.tc-tab-selected {
	color: #666666;
	background-color: #ffffff;
	border-left: 1px solid #d8d8d8;
	border-top: 1px solid #d8d8d8;
	border-right: 1px solid #d8d8d8;
}.tc-tab-buttons button {
	color: #666666;
	padding: 3px 5px 3px 5px;
	margin-right: 0.3em;
	font-weight: 300;
	border: none;
	background: inherit;
	background-color: #d8d8d8;
	border-left: 1px solid #cccccc;
	border-top: 1px solid #cccccc;
	border-right: 1px solid #cccccc;
	border-top-left-radius: 2px;
	border-top-right-radius: 2px;
	border-bottom-left-radius: 0;
	border-bottom-right-radius: 0;
}.tc-tab-buttons.tc-vertical button {
	display: block;
	width: 100%;
	margin-top: 3px;
	margin-right: 0;
	text-align: right;
	background-color: #d8d8d8;
	border-left: 1px solid #cccccc;
	border-bottom: 1px solid #cccccc;
	border-right: none;
	border-top-left-radius: 2px;
	border-bottom-left-radius: 2px;
	border-top-right-radius: 0;
	border-bottom-right-radius: 0;
}.tc-tab-buttons.tc-vertical button.tc-tab-selected {
	background-color: #ffffff;
	border-right: 1px solid #ffffff;
}.tc-tab-divider {
	border-top: 1px solid #d8d8d8;
}.tc-tab-divider.tc-vertical  {
	display: none;
}.tc-tab-content {
	margin-top: 14px;
}.tc-tab-content.tc-vertical  {
    word-break: break-word;
	display: inline-block;
	vertical-align: top;
	padding-top: 0;
	padding-left: 14px;
	border-left: 1px solid #cccccc;
	-webkit-flex: 1 0 70%;
	flex: 1 0 70%;
}.tc-sidebar-lists .tc-tab-buttons {
	margin-bottom: -1px;
}.tc-sidebar-lists .tc-tab-buttons button.tc-tab-selected {
	background-color: #f4f4f4;
	color: ;
	border-left: 1px solid #d8d8d8;
	border-top: 1px solid #d8d8d8;
	border-right: 1px solid #d8d8d8;
}.tc-sidebar-lists .tc-tab-buttons button {
	background-color: #e0e0e0;
	color: #666666;
	border-left: 1px solid #cccccc;
	border-top: 1px solid #cccccc;
	border-right: 1px solid #cccccc;
}.tc-sidebar-lists .tc-tab-divider {
	border-top: 1px solid #e4e4e4;
}.tc-more-sidebar > .tc-tab-set > .tc-tab-buttons > button {
	display: block;
	width: 100%;
	background-color: #e0e0e0;
	border-top: none;
	border-left: none;
	border-bottom: none;
	border-right: 1px solid #ccc;
	margin-bottom: inherit;
}.tc-more-sidebar > .tc-tab-set > .tc-tab-buttons > button.tc-tab-selected {
	background-color: #f4f4f4;
	border: none;
}/*
** Manager
*/.tc-manager-wrapper {
	
}.tc-manager-controls {
	
}.tc-manager-control {
	margin: 0.5em 0;
}.tc-manager-list {
	width: 100%;
	border-top: 1px solid #bbb;
	border-left: 1px solid #bbb;
	border-right: 1px solid #bbb;
}.tc-manager-list-item {}.tc-manager-list-item-heading {
    display: block;
    width: 100%;
    text-align: left;	
	border-bottom: 1px solid #bbb;
	padding: 3px;
}.tc-manager-list-item-heading-selected {
	font-weight: bold;
	color: #ffffff;
	fill: #ffffff;
	background-color: #333333;
}.tc-manager-list-item-heading:hover {
	background: #5778d8;
	color: #ffffff;
}.tc-manager-list-item-content {
	display: flex;
}.tc-manager-list-item-content-sidebar {
    flex: 1 0;
    background: #f8f8f8;
    border-right: 0.5em solid #bbb;
    border-bottom: 0.5em solid #bbb;
    white-space: nowrap;
}.tc-manager-list-item-content-item-heading {
	display: block;
	width: 100%;
	text-align: left;
    background: #bbb;
	text-transform: uppercase;
	font-size: 0.6em;
	font-weight: bold;
    padding: 0.5em 0 0.5em 0;
}.tc-manager-list-item-content-item-body {
	padding: 0 0.5em 0 0.5em;
}.tc-manager-list-item-content-item-body > pre {
	margin: 0.5em 0 0.5em 0;
	border: none;
	background: inherit;
}.tc-manager-list-item-content-tiddler {
    flex: 3 1;
    border-left: 0.5em solid #bbb;
    border-right: 0.5em solid #bbb;
    border-bottom: 0.5em solid #bbb;
}.tc-manager-list-item-content-item-body > table {
	border: none;
	padding: 0;
	margin: 0;
}.tc-manager-list-item-content-item-body > table td {
	border: none;
}.tc-manager-icon-editor > button {
	width: 100%;
}.tc-manager-icon-editor > button > svg,
.tc-manager-icon-editor > button > button {
	width: 100%;
	height: auto;
}/*
** Alerts
*/.tc-alerts {
	position: fixed;
	top: 0;
	left: 0;
	max-width: 500px;
	z-index: 20000;
}.tc-alert {
	position: relative;
	margin: 28px;
	padding: 14px 14px 14px 14px;
	border: 2px solid #b99e2f;
	background-color: #ffe476;
}.tc-alert-toolbar {
	position: absolute;
	top: 14px;
	right: 14px;
}.tc-alert-toolbar svg {
	fill: #b99e2f;
}.tc-alert-subtitle {
	color: #b99e2f;
	font-weight: bold;
}.tc-alert-highlight {
	color: #881122;
}@media (min-width: 960px) {.tc-static-alert {
		position: relative;
	}.tc-static-alert-inner {
		position: absolute;
		z-index: 100;
	}}.tc-static-alert-inner {
	padding: 0 2px 2px 42px;
	color: #aaaaaa;
}/*
** Floating drafts list
*/.tc-drafts-list {
	z-index: 2000;
	position: fixed;
	font-size: 0.8em;
	left: 0;
	bottom: 0;
}.tc-drafts-list a {
	margin: 0 0.5em;
	padding: 4px 4px;
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
	border: 1px solid #ffffff;
	border-bottom-none;
	background: #ff0000;
	color: #ffffff;
	fill: #ffffff;
}.tc-drafts-list a:hover {
	text-decoration: none;
	background: #333333;
	color: #ffffff;
	fill: #ffffff;
}.tc-drafts-list a svg {
	width: 1em;
	height: 1em;
	vertical-align: text-bottom;
}/*
** Control panel
*/.tc-control-panel td {
	padding: 4px;
}.tc-control-panel table, .tc-control-panel table input, .tc-control-panel table textarea {
	width: 100%;
}.tc-plugin-info {
	display: block;
	border: 1px solid #bbb;
	background-colour: #ffffff;
	margin: 0.5em 0 0.5em 0;
	padding: 4px;
}.tc-plugin-info-disabled {
	background: -webkit-repeating-linear-gradient(45deg, #ff0, #ff0 10px, #eee 10px, #eee 20px);
	background: repeating-linear-gradient(45deg, #ff0, #ff0 10px, #eee 10px, #eee 20px);
}.tc-plugin-info-disabled:hover {
	background: -webkit-repeating-linear-gradient(45deg, #aa0, #aa0 10px, #888 10px, #888 20px);
	background: repeating-linear-gradient(45deg, #aa0, #aa0 10px, #888 10px, #888 20px);
}a.tc-tiddlylink.tc-plugin-info:hover {
	text-decoration: none;
	background-color: #5778d8;
	color: #ffffff;
	fill: #333333;
}a.tc-tiddlylink.tc-plugin-info:hover .tc-plugin-info > .tc-plugin-info-chunk > svg {
	fill: #333333;
}.tc-plugin-info-chunk {
	display: inline-block;
	vertical-align: middle;
}.tc-plugin-info-chunk h1 {
	font-size: 1em;
	margin: 2px 0 2px 0;
}.tc-plugin-info-chunk h2 {
	font-size: 0.8em;
	margin: 2px 0 2px 0;
}.tc-plugin-info-chunk div {
	font-size: 0.7em;
	margin: 2px 0 2px 0;
}.tc-plugin-info:hover > .tc-plugin-info-chunk > img, .tc-plugin-info:hover > .tc-plugin-info-chunk > svg {
	width: 2em;
	height: 2em;
	fill: #333333;
}.tc-plugin-info > .tc-plugin-info-chunk > img, .tc-plugin-info > .tc-plugin-info-chunk > svg {
	width: 2em;
	height: 2em;
	fill: #bbb;
}.tc-plugin-info.tc-small-icon > .tc-plugin-info-chunk > img, .tc-plugin-info.tc-small-icon > .tc-plugin-info-chunk > svg {
	width: 1em;
	height: 1em;
}.tc-plugin-info-dropdown {
	border: 1px solid #bbb;
	margin-top: -8px;
}.tc-plugin-info-dropdown-message {
	background: #ecf2ff;
	padding: 0.5em 1em 0.5em 1em;
	font-weight: bold;
	font-size: 0.8em;
}.tc-plugin-info-dropdown-body {
	padding: 1em 1em 1em 1em;
}.tc-check-list {
	line-height: 2em;
}.tc-check-list .tc-image-button {
	height: 1.5em;
}/*
** Message boxes
*/.tc-message-box {
	border: 1px solid #cfd6e6;
	background: #ecf2ff;
	padding: 0px 21px 0px 21px;
	font-size: 12px;
	line-height: 18px;
	color: #547599;
}.tc-message-box svg {
	width: 1em;
	height: 1em;
    vertical-align: text-bottom;
}/*
** Pictures
*/.tc-bordered-image {
	border: 1px solid #bbb;
	padding: 5px;
	margin: 5px;
}/*
** Floats
*/.tc-float-right {
	float: right;
}/*
** Chooser
*/.tc-chooser {
	border-right: 1px solid #f0f0f0;
	border-left: 1px solid #f0f0f0;
}.tc-chooser-item {
	border-bottom: 1px solid #f0f0f0;
	border-top: 1px solid #f0f0f0;
	padding: 2px 4px 2px 14px;
}.tc-drop-down .tc-chooser-item {
	padding: 2px;
}.tc-chosen,
.tc-chooser-item:hover {
	background-color: #f0f0f0;
	border-color: #a8a8a8;
}.tc-chosen .tc-tiddlylink {
	cursor:default;
}.tc-chooser-item .tc-tiddlylink {
	display: block;
	text-decoration: none;
	background-color: transparent;
}.tc-chooser-item:hover .tc-tiddlylink:hover {
	text-decoration: none;
}.tc-drop-down .tc-chosen .tc-tiddlylink,
.tc-drop-down .tc-chooser-item .tc-tiddlylink:hover {
	color: #333333;
}.tc-chosen > .tc-tiddlylink:before {
	margin-left: -10px;
	position: relative;
	content: "» ";
}.tc-chooser-item svg,
.tc-chooser-item img{
	width: 1em;
	height: 1em;
	vertical-align: middle;
}.tc-language-chooser .tc-image-button img {
	width: 2em;
	vertical-align: -0.15em;
}/*
** Palette swatches
*/.tc-swatches-horiz {
}.tc-swatches-horiz .tc-swatch {
	display: inline-block;
}.tc-swatch {
	width: 2em;
	height: 2em;
	margin: 0.4em;
	border: 1px solid #888;
}/*
** Table of contents
*/.tc-sidebar-lists .tc-table-of-contents {
	white-space: nowrap;
}.tc-table-of-contents button {
	color: #acacac;
}.tc-table-of-contents svg {
	width: 0.7em;
	height: 0.7em;
	vertical-align: middle;
	fill: #acacac;
}.tc-table-of-contents ol {
	list-style-type: none;
	padding-left: 0;
}.tc-table-of-contents ol ol {
	padding-left: 1em;
}.tc-table-of-contents li {
	font-size: 1.0em;
	font-weight: bold;
}.tc-table-of-contents li a {
	font-weight: bold;
}.tc-table-of-contents li li {
	font-size: 0.95em;
	font-weight: normal;
	line-height: 1.4;
}.tc-table-of-contents li li a {
	font-weight: normal;
}.tc-table-of-contents li li li {
	font-size: 0.95em;
	font-weight: 200;
	line-height: 1.5;
}.tc-table-of-contents li li li li {
	font-size: 0.95em;
	font-weight: 200;
}.tc-tabbed-table-of-contents {
	display: -webkit-flex;
	display: flex;
}.tc-tabbed-table-of-contents .tc-table-of-contents {
	z-index: 100;
	display: inline-block;
	padding-left: 1em;
	max-width: 50%;
	-webkit-flex: 0 0 auto;
	flex: 0 0 auto;
	background: #d8d8d8;
	border-left: 1px solid #cccccc;
	border-top: 1px solid #cccccc;
	border-bottom: 1px solid #cccccc;
}.tc-tabbed-table-of-contents .tc-table-of-contents .toc-item > a,
.tc-tabbed-table-of-contents .tc-table-of-contents .toc-item-selected > a {
	display: block;
	padding: 0.12em 1em 0.12em 0.25em;
}.tc-tabbed-table-of-contents .tc-table-of-contents .toc-item > a {
	border-top: 1px solid #d8d8d8;
	border-left: 1px solid #d8d8d8;
	border-bottom: 1px solid #d8d8d8;
}.tc-tabbed-table-of-contents .tc-table-of-contents .toc-item > a:hover {
	text-decoration: none;
	border-top: 1px solid #cccccc;
	border-left: 1px solid #cccccc;
	border-bottom: 1px solid #cccccc;
	background: #cccccc;
}.tc-tabbed-table-of-contents .tc-table-of-contents .toc-item-selected > a {
	border-top: 1px solid #cccccc;
	border-left: 1px solid #cccccc;
	border-bottom: 1px solid #cccccc;
	background: #ffffff;
	margin-right: -1px;
}.tc-tabbed-table-of-contents .tc-table-of-contents .toc-item-selected > a:hover {
	text-decoration: none;
}.tc-tabbed-table-of-contents .tc-tabbed-table-of-contents-content {
	display: inline-block;
	vertical-align: top;
	padding-left: 1.5em;
	padding-right: 1.5em;
	border: 1px solid #cccccc;
	-webkit-flex: 1 0 50%;
	flex: 1 0 50%;
}/*
** Dirty indicator
*/body.tc-dirty span.tc-dirty-indicator, body.tc-dirty span.tc-dirty-indicator svg {
	fill: #ff0000;
	color: #ff0000;
}/*
** File inputs
*/.tc-file-input-wrapper {
	position: relative;
	overflow: hidden;
	display: inline-block;
	vertical-align: middle;
}.tc-file-input-wrapper input[type=file] {
	position: absolute;
	top: 0;
	left: 0;
	right: 0;
	bottom: 0;
	font-size: 999px;
	max-width: 100%;
	max-height: 100%;
	filter: alpha(opacity=0);
	opacity: 0;
	outline: none;
	background: white;
	cursor: pointer;
	display: inline-block;
}/*
** Thumbnail macros
*/.tc-thumbnail-wrapper {
	position: relative;
	display: inline-block;
	margin: 6px;
	vertical-align: top;
}.tc-thumbnail-right-wrapper {
	float:right;
	margin: 0.5em 0 0.5em 0.5em;
}.tc-thumbnail-image {
	text-align: center;
	overflow: hidden;
	border-radius: 3px;
}.tc-thumbnail-image svg,
.tc-thumbnail-image img {
	filter: alpha(opacity=1);
	opacity: 1;
	min-width: 100%;
	min-height: 100%;
	max-width: 100%;
}.tc-thumbnail-wrapper:hover .tc-thumbnail-image svg,
.tc-thumbnail-wrapper:hover .tc-thumbnail-image img {
	filter: alpha(opacity=0.8);
	opacity: 0.8;
}.tc-thumbnail-background {
	position: absolute;
	border-radius: 3px;
}.tc-thumbnail-icon svg,
.tc-thumbnail-icon img {
	width: 3em;
	height: 3em;
	
  -webkit-filter: drop-shadow(2px 2px 4px rgba(0,0,0,0.3));
     -moz-filter: drop-shadow(2px 2px 4px rgba(0,0,0,0.3));
          filter: drop-shadow(2px 2px 4px rgba(0,0,0,0.3));

}.tc-thumbnail-wrapper:hover .tc-thumbnail-icon svg,
.tc-thumbnail-wrapper:hover .tc-thumbnail-icon img {
	fill: #fff;
	
  -webkit-filter: drop-shadow(3px 3px 4px rgba(0,0,0,0.6));
     -moz-filter: drop-shadow(3px 3px 4px rgba(0,0,0,0.6));
          filter: drop-shadow(3px 3px 4px rgba(0,0,0,0.6));

}.tc-thumbnail-icon {
	position: absolute;
	top: 0;
	left: 0;
	right: 0;
	bottom: 0;
	display: -webkit-flex;
	-webkit-align-items: center;
	-webkit-justify-content: center;
	display: flex;
	align-items: center;
	justify-content: center;
}.tc-thumbnail-caption {
	position: absolute;
	background-color: #777;
	color: #fff;
	text-align: center;
	bottom: 0;
	width: 100%;
	filter: alpha(opacity=0.9);
	opacity: 0.9;
	line-height: 1.4;
	border-bottom-left-radius: 3px;
	border-bottom-right-radius: 3px;
}.tc-thumbnail-wrapper:hover .tc-thumbnail-caption {
	filter: alpha(opacity=1);
	opacity: 1;
}/*
** Diffs
*/.tc-diff-equal {
	background-color: ;
	color: #333333;
}.tc-diff-insert {
	background-color: #aaefad;
	color: #333333;
}.tc-diff-delete {
	background-color: #ffc9c9;
	color: #333333;
}.tc-diff-invisible {
	background-color: ;
	color: #bbb;
}.tc-diff-tiddlers th {
	text-align: right;
	background: #ffffff;
	font-weight: normal;
	font-style: italic;
}.tc-diff-tiddlers pre {
    margin: 0;
    padding: 0;
    border: none;
    background: none;
}/*
** Errors
*/.tc-error {
	background: #f00;
	color: #fff;
}/*
** Tree macro
*/.tc-tree div {
    	padding-left: 14px;
}.tc-tree ol {
    	list-style-type: none;
    	padding-left: 0;
    	margin-top: 0;
}.tc-tree ol ol {
    	padding-left: 1em;    
}.tc-tree button { 
    	color: #acacac;
}.tc-tree svg {
     	fill: #acacac;
}.tc-tree span svg {
    	width: 1em;
    	height: 1em;
    	vertical-align: baseline;
}.tc-tree li span {
    	color: lightgray;
}select {
        color: ;
        background: ;
}

@media (min-width: 960px) {html .tc-page-container {
		text-align: center;
	}html .tc-story-river {
		position: relative;
		width: 770px;
		padding: 42px;
		margin: 0 auto;
		text-align: left;
	}html .tc-sidebar-scrollable {
		text-align: left;
		left: 50%;
		right: 0;
		margin-left: 343px;
	}
}



</style>
</head>
<body class="tc-body">



<section class="tc-story-river">`;
}



string researchTop() {
	return `<!doctype html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
<meta name="generator" content="TiddlyWiki" />
<meta name="tiddlywiki-version" content="5.1.19" />
<meta name="format-detection" content="telephone=no">
<link id="faviconLink" rel="shortcut icon" href="favicon.ico">
<script src='https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.5/MathJax.js?config=TeX-MML-AM_CHTML' async></script>
<title>Title goes here</title>
<div id="styleArea">
<style data-tiddler-title="$:/boot/boot.css" data-tiddler-type="text/css" type="text/css">/*
Basic styles used before we boot up the parsing engine
*/

/*
Error message and password prompt
*/

.tc-error-form {
	font-family: sans-serif;
	color: #fff;
	z-index: 20000;
	position: fixed;
	background-color: rgb(255, 75, 75);
	border: 8px solid rgb(255, 0, 0);
	border-radius: 8px;
	width: 50%;
	margin-left: 25%;
	margin-top: 4em;
	padding: 0 2em 1em 2em;
}

.tc-error-form h1 {
	text-align: center;
}

.tc-error-prompt {
	text-align: center;
	color: #000;
}

.tc-error-message {
	overflow: auto;
	max-height: 40em;
	padding-right: 1em;
	margin: 1em 0;
	white-space: pre-line;
}

.tc-password-wrapper {
    font-family: sans-serif;
	z-index: 20000;
	position: fixed;
	text-align: center;
	width: 200px;
	top: 4em;
	left: 50%;
	margin-left: -144px; /* - width/2 - paddingHorz/2 - border */
	padding: 16px 16px 16px 16px;
	border-radius: 8px;
}

.tc-password-wrapper {
	color: #000;
	text-shadow: 0 1px 0 rgba(255, 255, 255, 0.5);
	background-color: rgb(197, 235, 183);
	border: 8px solid rgb(164, 197, 152);
}

.tc-password-wrapper form {
	text-align: left;
}

.tc-password-wrapper h1 {
	font-size: 16px;
	line-height: 20px;
	padding-bottom: 16px;
}

.tc-password-wrapper input {
	width: 100%;
}
</style>
</div>
<style type="text/css">

.tc-sidebar-header {
	text-shadow: 0 1px 0 rgba(255,255,255, 0.8);
}.tc-tiddler-info {
	
  -webkit-box-shadow: inset 1px 2px 3px rgba(0,0,0,0.1);
     -moz-box-shadow: inset 1px 2px 3px rgba(0,0,0,0.1);
          box-shadow: inset 1px 2px 3px rgba(0,0,0,0.1);

}@media screen {
	.tc-tiddler-frame {
		
  -webkit-box-shadow: 1px 1px 5px rgba(0, 0, 0, 0.3);
     -moz-box-shadow: 1px 1px 5px rgba(0, 0, 0, 0.3);
          box-shadow: 1px 1px 5px rgba(0, 0, 0, 0.3);

	}
}@media (max-width: 960px) {
	.tc-tiddler-frame {
		
  -webkit-box-shadow: none;
     -moz-box-shadow: none;
          box-shadow: none;

	}
}.tc-page-controls button svg, .tc-tiddler-controls button svg, .tc-topbar button svg {
	
  -webkit-transition: fill 150ms ease-in-out;
     -moz-transition: fill 150ms ease-in-out;
          transition: fill 150ms ease-in-out;

}.tc-tiddler-controls button.tc-selected,
.tc-page-controls button.tc-selected {
	
  -webkit-filter: drop-shadow(0px -1px 2px rgba(0,0,0,0.25));
     -moz-filter: drop-shadow(0px -1px 2px rgba(0,0,0,0.25));
          filter: drop-shadow(0px -1px 2px rgba(0,0,0,0.25));

}.tc-tiddler-frame input.tc-edit-texteditor {
	
  -webkit-box-shadow: inset 0 1px 8px rgba(0, 0, 0, 0.15);
     -moz-box-shadow: inset 0 1px 8px rgba(0, 0, 0, 0.15);
          box-shadow: inset 0 1px 8px rgba(0, 0, 0, 0.15);

}.tc-edit-tags {
	
  -webkit-box-shadow: inset 0 1px 8px rgba(0, 0, 0, 0.15);
     -moz-box-shadow: inset 0 1px 8px rgba(0, 0, 0, 0.15);
          box-shadow: inset 0 1px 8px rgba(0, 0, 0, 0.15);

}.tc-tiddler-frame .tc-edit-tags input.tc-edit-texteditor {
	
  -webkit-box-shadow: none;
     -moz-box-shadow: none;
          box-shadow: none;

	border: none;
	outline: none;
}textarea.tc-edit-texteditor {
	font-family: ;
}canvas.tc-edit-bitmapeditor  {
	
  -webkit-box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.5);
     -moz-box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.5);
          box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.5);

}.tc-drop-down {
	border-radius: 4px;
	
  -webkit-box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.5);
     -moz-box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.5);
          box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.5);

}.tc-block-dropdown {
	border-radius: 4px;
	
  -webkit-box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.5);
     -moz-box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.5);
          box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.5);

}.tc-modal {
	border-radius: 6px;
	
  -webkit-box-shadow: 0 3px 7px rgba(0,0,0,0.3);
     -moz-box-shadow: 0 3px 7px rgba(0,0,0,0.3);
          box-shadow: 0 3px 7px rgba(0,0,0,0.3);

}.tc-modal-footer {
	border-radius: 0 0 6px 6px;
	
  -webkit-box-shadow: inset 0 1px 0 #fff;
     -moz-box-shadow: inset 0 1px 0 #fff;
          box-shadow: inset 0 1px 0 #fff;
;
}.tc-alert {
	border-radius: 6px;
	
  -webkit-box-shadow: 0 3px 7px rgba(0,0,0,0.6);
     -moz-box-shadow: 0 3px 7px rgba(0,0,0,0.6);
          box-shadow: 0 3px 7px rgba(0,0,0,0.6);

}.tc-notification {
	border-radius: 6px;
	
  -webkit-box-shadow: 0 3px 7px rgba(0,0,0,0.3);
     -moz-box-shadow: 0 3px 7px rgba(0,0,0,0.3);
          box-shadow: 0 3px 7px rgba(0,0,0,0.3);

	text-shadow: 0 1px 0 rgba(255,255,255, 0.8);
}.tc-sidebar-lists .tc-tab-set .tc-tab-divider {
	border-top: none;
	height: 1px;
	
background-image: linear-gradient(left, rgba(0,0,0,0.15) 0%, rgba(0,0,0,0.0) 100%);
background-image: -o-linear-gradient(left, rgba(0,0,0,0.15) 0%, rgba(0,0,0,0.0) 100%);
background-image: -moz-linear-gradient(left, rgba(0,0,0,0.15) 0%, rgba(0,0,0,0.0) 100%);
background-image: -webkit-linear-gradient(left, rgba(0,0,0,0.15) 0%, rgba(0,0,0,0.0) 100%);
background-image: -ms-linear-gradient(left, rgba(0,0,0,0.15) 0%, rgba(0,0,0,0.0) 100%);

}.tc-more-sidebar > .tc-tab-set > .tc-tab-buttons > button {
	
background-image: linear-gradient(left, rgba(0,0,0,0.01) 0%, rgba(0,0,0,0.1) 100%);
background-image: -o-linear-gradient(left, rgba(0,0,0,0.01) 0%, rgba(0,0,0,0.1) 100%);
background-image: -moz-linear-gradient(left, rgba(0,0,0,0.01) 0%, rgba(0,0,0,0.1) 100%);
background-image: -webkit-linear-gradient(left, rgba(0,0,0,0.01) 0%, rgba(0,0,0,0.1) 100%);
background-image: -ms-linear-gradient(left, rgba(0,0,0,0.01) 0%, rgba(0,0,0,0.1) 100%);

}.tc-more-sidebar > .tc-tab-set > .tc-tab-buttons > button.tc-tab-selected {
	
background-image: linear-gradient(left, rgba(0,0,0,0.05) 0%, rgba(255,255,255,0.05) 100%);
background-image: -o-linear-gradient(left, rgba(0,0,0,0.05) 0%, rgba(255,255,255,0.05) 100%);
background-image: -moz-linear-gradient(left, rgba(0,0,0,0.05) 0%, rgba(255,255,255,0.05) 100%);
background-image: -webkit-linear-gradient(left, rgba(0,0,0,0.05) 0%, rgba(255,255,255,0.05) 100%);
background-image: -ms-linear-gradient(left, rgba(0,0,0,0.05) 0%, rgba(255,255,255,0.05) 100%);

}.tc-message-box img {
	
  -webkit-box-shadow: 1px 1px 3px rgba(0,0,0,0.5);
     -moz-box-shadow: 1px 1px 3px rgba(0,0,0,0.5);
          box-shadow: 1px 1px 3px rgba(0,0,0,0.5);

}.tc-plugin-info {
	
  -webkit-box-shadow: 1px 1px 3px rgba(0,0,0,0.5);
     -moz-box-shadow: 1px 1px 3px rgba(0,0,0,0.5);
          box-shadow: 1px 1px 3px rgba(0,0,0,0.5);

}


/*
** Start with the normalize CSS reset, and then belay some of its effects
*//*! normalize.css v3.0.0 | MIT License | git.io/normalize */

/**
 * 1. Set default font family to sans-serif.
 * 2. Prevent iOS text size adjust after orientation change, without disabling
 *    user zoom.
 */

html {
  font-family: sans-serif; /* 1 */
  -ms-text-size-adjust: 100%; /* 2 */
  -webkit-text-size-adjust: 100%; /* 2 */
}

/**
 * Remove default margin.
 */

body {
  margin: 0;
}

/* HTML5 display definitions
   ========================================================================== */

article,
aside,
details,
figcaption,
figure,
footer,
header,
hgroup,
main,
nav,
section,
summary {
  display: block;
}


audio,
canvas,
progress,
video {
  display: inline-block; /* 1 */
  vertical-align: baseline; /* 2 */
}


audio:not([controls]) {
  display: none;
  height: 0;
}


[hidden],
template {
  display: none;
}

/* Links
   ========================================================================== */

/**
 * Remove the gray background color from active links in IE 10.
 */

a {
  background: transparent;
}

/**
 * Improve readability when focused and also mouse hovered in all browsers.
 */

a:active,
a:hover {
  outline: 0;
}

/* Text-level semantics
   ========================================================================== */

/**
 * Address styling not present in IE 8/9, Safari 5, and Chrome.
 */

abbr[title] {
  border-bottom: 1px dotted;
}


b,
strong {
  font-weight: bold;
}

/**
 * Address styling not present in Safari 5 and Chrome.
 */

dfn {
  font-style: italic;
}


h1 {
  font-size: 2em;
  margin: 0.67em 0;
}

/**
 * Address styling not present in IE 8/9.
 */

mark {
  background: #ff0;
  color: #000;
}

/**
 * Address inconsistent and variable font size in all browsers.
 */

small {
  font-size: 80%;
}


sub,
sup {
  font-size: 75%;
  line-height: 0;
  position: relative;
  vertical-align: baseline;
}

sup {
  top: -0.5em;
}

sub {
  bottom: -0.25em;
}

/* Embedded content
   ========================================================================== */


img {
  border: 0;
}

/**
 * Correct overflow displayed oddly in IE 9.
 */

svg:not(:root) {
  overflow: hidden;
}

/* Grouping content
   ========================================================================== */

/**
 * Address margin not present in IE 8/9 and Safari 5.
 */

figure {
  margin: 1em 40px;
}

/**
 * Address differences between Firefox and other browsers.
 */

hr {
  -moz-box-sizing: content-box;
  box-sizing: content-box;
  height: 0;
}

/**
 * Contain overflow in all browsers.
 */

pre {
  overflow: auto;
}

code,
kbd,
pre,
samp {
  font-family: monospace, monospace;
  font-size: 1em;
}

/* Forms
   ========================================================================== */


/**
 * 1. Correct color not being inherited.
 *    Known issue: affects color of disabled elements.
 * 2. Correct font properties not being inherited.
 * 3. Address margins set differently in Firefox 4+, Safari 5, and Chrome.
 */

button,
input,
optgroup,
select,
textarea {
  color: inherit; /* 1 */
  font: inherit; /* 2 */
  margin: 0; /* 3 */
}


button {
  overflow: visible;
}


button,
select {
  text-transform: none;
}


button,
html input[type="button"], /* 1 */
input[type="reset"],
input[type="submit"] {
  -webkit-appearance: button; /* 2 */
  cursor: pointer; /* 3 */
}

/**
 * Re-set default cursor for disabled elements.
 */

button[disabled],
html input[disabled] {
  cursor: default;
}

/**
 * Remove inner padding and border in Firefox 4+.
 */

button::-moz-focus-inner,
input::-moz-focus-inner {
  border: 0;
  padding: 0;
}


input {
  line-height: normal;
}


input[type="checkbox"],
input[type="radio"] {
  box-sizing: border-box; /* 1 */
  padding: 0; /* 2 */
}

input[type="number"]::-webkit-inner-spin-button,
input[type="number"]::-webkit-outer-spin-button {
  height: auto;
}

/**
 * 1. Address appearance set to searchfield in Safari 5 and Chrome.
 * 2. Address box-sizing set to border-box in Safari 5 and Chrome
 *    (include -moz to future-proof).
 */

input[type="search"] {
  -webkit-appearance: textfield; /* 1 */
  -moz-box-sizing: content-box;
  -webkit-box-sizing: content-box; /* 2 */
  box-sizing: content-box;
}

/**
 * Remove inner padding and search cancel button in Safari and Chrome on OS X.
 * Safari (but not Chrome) clips the cancel button when the search input has
 * padding (and textfield appearance).
 */

input[type="search"]::-webkit-search-cancel-button,
input[type="search"]::-webkit-search-decoration {
  -webkit-appearance: none;
}

/**
 * Define consistent border, margin, and padding.
 */

fieldset {
  border: 1px solid #c0c0c0;
  margin: 0 2px;
  padding: 0.35em 0.625em 0.75em;
}

/**
 * 1. Correct color not being inherited in IE 8/9.
 * 2. Remove padding so people aren't caught out if they zero out fieldsets.
 */

legend {
  border: 0; /* 1 */
  padding: 0; /* 2 */
}

/**
 * Remove default vertical scrollbar in IE 8/9.
 */

textarea {
  overflow: auto;
}

/**
 * Don't inherit the font-weight (applied by a rule above).
 * NOTE: the default cannot safely be changed in Chrome and Safari on OS X.
 */

optgroup {
  font-weight: bold;
}

/* Tables
   ========================================================================== */

/**
 * Remove most spacing between table cells.
 */

table {
  border-collapse: collapse;
  border-spacing: 0;
}

td,
th {
  padding: 0;
}
*, input[type="search"] {
	box-sizing: border-box;
	-moz-box-sizing: border-box;
	-webkit-box-sizing: border-box;
}html button {
	line-height: 1.2;
	color: ;
	background: ;
	border-color: ;
}/*
** Basic element styles
*/html {
	font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
	text-rendering: optimizeLegibility; /* Enables kerning and ligatures etc. */
	-webkit-font-smoothing: antialiased;
	-moz-osx-font-smoothing: grayscale;
}html:-webkit-full-screen {
	background-color: #f4f4f4;
}body.tc-body {
	font-size: 14px;
	line-height: 20px;
	word-wrap: break-word;
	


	color: #333333;
	background-color: #f4f4f4;
	fill: #333333;
}h1, h2, h3, h4, h5, h6 {
	line-height: 1.2;
	font-weight: 300;
}pre {
	display: block;
	padding: 14px;
	margin-top: 1em;
	margin-bottom: 1em;
	word-break: normal;
	word-wrap: break-word;
	white-space: pre-wrap;
	background-color: #f5f5f5;
	border: 1px solid #cccccc;
	padding: 0 3px 2px;
	border-radius: 3px;
	font-family: "SFMono-Regular",Consolas,"Liberation Mono",Menlo,Courier,monospace;
}code {
	color: #dd1144;
	background-color: #f7f7f9;
	border: 1px solid #e1e1e8;
	white-space: pre-wrap;
	padding: 0 3px 2px;
	border-radius: 3px;
	font-family: "SFMono-Regular",Consolas,"Liberation Mono",Menlo,Courier,monospace;
}blockquote {
	border-left: 5px solid #bbb;
	margin-left: 25px;
	padding-left: 10px;
	quotes: "\201C""\201D""\2018""\2019";
}blockquote.tc-big-quote {
	font-family: Georgia, serif;
	position: relative;
	background: #f5f5f5;
	border-left: none;
	margin-left: 50px;
	margin-right: 50px;
	padding: 10px;
    border-radius: 8px;
}blockquote.tc-big-quote cite:before {
	content: "\2014 \2009";
}blockquote.tc-big-quote:before {
	font-family: Georgia, serif;
	color: #bbb;
	content: open-quote;
	font-size: 8em;
	line-height: 0.1em;
	margin-right: 0.25em;
	vertical-align: -0.4em;
	position: absolute;
    left: -50px;
    top: 42px;
}blockquote.tc-big-quote:after {
	font-family: Georgia, serif;
	color: #bbb;
	content: close-quote;
	font-size: 8em;
	line-height: 0.1em;
	margin-right: 0.25em;
	vertical-align: -0.4em;
	position: absolute;
    right: -80px;
    bottom: -20px;
}dl dt {
	font-weight: bold;
	margin-top: 6px;
}textarea,
input[type=text],
input[type=search],
input[type=""],
input:not([type]) {
	color: #333333;
	background: #ffffff;
}input[type="checkbox"] {
  vertical-align: middle;
}.tc-muted {
	color: #bbb;
}svg.tc-image-button {
	padding: 0px 1px 1px 0px;
}.tc-icon-wrapper > svg {
	width: 1em;
	height: 1em;
}kbd {
	display: inline-block;
	padding: 3px 5px;
	font-size: 0.8em;
	line-height: 1.2;
	color: #333333;
	vertical-align: middle;
	background-color: #ffffff;
	border: solid 1px #bbb;
	border-bottom-color: #bbb;
	border-radius: 3px;
	box-shadow: inset 0 -1px 0 #bbb;
}/*
Markdown likes putting code elements inside pre elements
*/
pre > code {
	padding: 0;
	border: none;
	background-color: inherit;
	color: inherit;
}table {
	border: 1px solid #dddddd;
	width: auto;
	max-width: 100%;
	caption-side: bottom;
	margin-top: 1em;
	margin-bottom: 1em;
}table th, table td {
	padding: 0 7px 0 7px;
	border-top: 1px solid #dddddd;
	border-left: 1px solid #dddddd;
}table thead tr td, table th {
	background-color: #f0f0f0;
	font-weight: bold;
}table tfoot tr td {
	background-color: #a8a8a8;
}.tc-csv-table {
	white-space: nowrap;
}.tc-tiddler-frame img,
.tc-tiddler-frame svg,
.tc-tiddler-frame canvas,
.tc-tiddler-frame embed,
.tc-tiddler-frame iframe {
	max-width: 100%;
}.tc-tiddler-body > embed,
.tc-tiddler-body > iframe {
	width: 100%;
	height: 600px;
}/*
** Links
*/button.tc-tiddlylink,
a.tc-tiddlylink {
	text-decoration: none;
	font-weight: 500;
	color: #5778d8;
	-webkit-user-select: inherit; /* Otherwise the draggable attribute makes links impossible to select */
}.tc-sidebar-lists a.tc-tiddlylink {
	color: #999999;
}.tc-sidebar-lists a.tc-tiddlylink:hover {
	color: #444444;
}button.tc-tiddlylink:hover,
a.tc-tiddlylink:hover {
	text-decoration: underline;
}a.tc-tiddlylink-resolves {
}a.tc-tiddlylink-shadow {
	font-weight: bold;
}a.tc-tiddlylink-shadow.tc-tiddlylink-resolves {
	font-weight: normal;
}a.tc-tiddlylink-missing {
	font-style: italic;
}a.tc-tiddlylink-external {
	text-decoration: underline;
	color: #0000ee;
	background-color: inherit;
}a.tc-tiddlylink-external:visited {
	color: #0000aa;
	background-color: inherit;
}a.tc-tiddlylink-external:hover {
	color: inherit;
	background-color: inherit;
}/*
** Drag and drop styles
*/.tc-tiddler-dragger {
	position: relative;
	z-index: -10000;
}.tc-tiddler-dragger-inner {
	position: absolute;
	top: -1000px;
	left: -1000px;
	display: inline-block;
	padding: 8px 20px;
	font-size: 16.9px;
	font-weight: bold;
	line-height: 20px;
	color: #ffffff;
	text-shadow: 0 1px 0 rgba(0, 0, 0, 1);
	white-space: nowrap;
	vertical-align: baseline;
	background-color: #333333;
	border-radius: 20px;
}.tc-tiddler-dragger-cover {
	position: absolute;
	background-color: #f4f4f4;
}.tc-dropzone {
	position: relative;
}.tc-dropzone.tc-dragover:before {
	z-index: 10000;
	display: block;
	position: fixed;
	top: 0;
	left: 0;
	right: 0;
	background: rgba(0,200,0,0.7);
	text-align: center;
	content: "Drop here (or use the 'Escape' key to cancel)";
}.tc-droppable > .tc-droppable-placeholder {
	display: none;
}.tc-droppable.tc-dragover > .tc-droppable-placeholder {
	display: block;
	border: 2px dashed rgba(0,200,0,0.7);
}.tc-draggable {
	cursor: move;
}/*
** Plugin reload warning
*/.tc-plugin-reload-warning {
	z-index: 1000;
	display: block;
	position: fixed;
	top: 0;
	left: 0;
	right: 0;
	background: #ffe476;
	text-align: center;
}/*
** Buttons
*/button svg, button img, label svg, label img {
	vertical-align: middle;
}.tc-btn-invisible {
	padding: 0;
	margin: 0;
	background: none;
	border: none;
    cursor: pointer;
}.tc-btn-boxed {
	font-size: 0.6em;
	padding: 0.2em;
	margin: 1px;
	background: none;
	border: 1px solid #cccccc;
	border-radius: 0.25em;
}html body.tc-body .tc-btn-boxed svg {
	font-size: 1.6666em;
}.tc-btn-boxed:hover {
	background: #bbb;
	color: #ffffff;
}html body.tc-body .tc-btn-boxed:hover svg {
	fill: #ffffff;
}.tc-btn-rounded {
	font-size: 0.5em;
	line-height: 2;
	padding: 0em 0.3em 0.2em 0.4em;
	margin: 1px;
	border: 1px solid #bbb;
	background: #bbb;
	color: #ffffff;
	border-radius: 2em;
}html body.tc-body .tc-btn-rounded svg {
	font-size: 1.6666em;
	fill: #ffffff;
}.tc-btn-rounded:hover {
	border: 1px solid #bbb;
	background: #ffffff;
	color: #bbb;
}html body.tc-body .tc-btn-rounded:hover svg {
	fill: #bbb;
}.tc-btn-icon svg {
	height: 1em;
	width: 1em;
	fill: #bbb;
}.tc-btn-text {
	padding: 0;
	margin: 0;
}/* used for documentation "fake" buttons */
.tc-btn-standard {
	line-height: 1.8;
	color: #667;
	background-color: #e0e0e0;
	border: 1px solid #888;
	padding: 2px 1px 2px 1px;
	margin: 1px 4px 1px 4px;
}.tc-btn-big-green {
	display: inline-block;
	padding: 8px;
	margin: 4px 8px 4px 8px;
	background: #34c734;
	color: #ffffff;
	fill: #ffffff;
	border: none;
	font-size: 1.2em;
	line-height: 1.4em;
	text-decoration: none;
}.tc-btn-big-green svg,
.tc-btn-big-green img {
	height: 2em;
	width: 2em;
	vertical-align: middle;
	fill: #ffffff;
}.tc-sidebar-lists input {
	color: #333333;
}.tc-sidebar-lists button {
	color: #333333;
	fill: #333333;
}.tc-sidebar-lists button.tc-btn-mini {
	color: #c0c0c0;
}.tc-sidebar-lists button.tc-btn-mini:hover {
	color: #444444;
}button svg.tc-image-button, button .tc-image-button img {
	height: 1em;
	width: 1em;
}.tc-unfold-banner {
	position: absolute;
	padding: 0;
	margin: 0;
	background: none;
	border: none;
	width: 100%;
	width: calc(100% + 2px);
	margin-left: -43px;
	text-align: center;
	border-top: 2px solid #f8f8f8;
	margin-top: 4px;
}.tc-unfold-banner:hover {
	background: #f8f8f8;
	border-top: 2px solid #dddddd;
}.tc-unfold-banner svg, .tc-fold-banner svg {
	height: 0.75em;
	fill: #cccccc;
}.tc-unfold-banner:hover svg, .tc-fold-banner:hover svg {
	fill: #888888;
}.tc-fold-banner {
	position: absolute;
	padding: 0;
	margin: 0;
	background: none;
	border: none;
	width: 23px;
	text-align: center;
	margin-left: -35px;
	top: 6px;
	bottom: 6px;
}.tc-fold-banner:hover {
	background: #f8f8f8;
}@media (max-width: 960px) {.tc-unfold-banner {
		position: static;
		width: calc(100% + 59px);
	}.tc-fold-banner {
		width: 16px;
		margin-left: -16px;
		font-size: 0.75em;
	}}/*
** Tags and missing tiddlers
*/.tc-tag-list-item {
	position: relative;
	display: inline-block;
	margin-right: 7px;
}.tc-tags-wrapper {
	margin: 4px 0 14px 0;
}.tc-missing-tiddler-label {
	font-style: italic;
	font-weight: normal;
	display: inline-block;
	font-size: 11.844px;
	line-height: 14px;
	white-space: nowrap;
	vertical-align: baseline;
}button.tc-tag-label, span.tc-tag-label {
	display: inline-block;
	padding: 0.16em 0.7em;
	font-size: 0.9em;
	font-weight: 400;
	line-height: 1.2em;
	color: #ffffff;
	white-space: nowrap;
	vertical-align: baseline;
	background-color: #ec6;
	border-radius: 1em;
}.tc-untagged-separator {
	width: 10em;
	left: 0;
	margin-left: 0;
	border: 0;
	height: 1px;
	background: #d8d8d8;
}button.tc-untagged-label {
	background-color: #999999;
}.tc-tag-label svg, .tc-tag-label img {
	height: 1em;
	width: 1em;
	vertical-align: text-bottom;
}.tc-tag-manager-table .tc-tag-label {
	white-space: normal;
}.tc-tag-manager-tag {
	width: 100%;
}button.tc-btn-invisible.tc-remove-tag-button {
	outline: none;
}/*
** Page layout
*/.tc-topbar {
	position: fixed;
	z-index: 1200;
}.tc-topbar-left {
	left: 29px;
	top: 5px;
}.tc-topbar-right {
	top: 5px;
	right: 29px;
}.tc-topbar button {
	padding: 8px;
}.tc-topbar svg {
	fill: #bbb;
}.tc-topbar button:hover svg {
	fill: #333333;
}.tc-sidebar-header {
	color: #acacac;
	fill: #acacac;
}.tc-sidebar-header .tc-title a.tc-tiddlylink-resolves {
	font-weight: 300;
}.tc-sidebar-header .tc-sidebar-lists p {
	margin-top: 3px;
	margin-bottom: 3px;
}.tc-sidebar-header .tc-missing-tiddler-label {
	color: #acacac;
}.tc-advanced-search input {
	width: 60%;
}.tc-search a svg {
	width: 1.2em;
	height: 1.2em;
	vertical-align: middle;
}.tc-page-controls {
	margin-top: 14px;
	font-size: 1.5em;
}.tc-page-controls .tc-drop-down {
  font-size: 1rem;
}.tc-page-controls button {
	margin-right: 0.5em;
}.tc-page-controls a.tc-tiddlylink:hover {
	text-decoration: none;
}.tc-page-controls img {
	width: 1em;
}.tc-page-controls svg {
	fill: #aaaaaa;
}.tc-page-controls button:hover svg, .tc-page-controls a:hover svg {
	fill: #000000;
}.tc-menu-list-item {
	white-space: nowrap;
}.tc-menu-list-count {
	font-weight: bold;
}.tc-menu-list-subitem {
	padding-left: 7px;
}.tc-story-river {
	position: relative;
}@media (max-width: 960px) {.tc-sidebar-header {
		padding: 14px;
		min-height: 32px;
		margin-top: 0px;
	}.tc-story-river {
		position: relative;
		padding: 0;
	}
}@media (min-width: 960px) {.tc-message-box {
		margin: 21px -21px 21px -21px;
	}.tc-sidebar-scrollable {
		position: fixed;
		top: 0px;
		left: 770px;
		bottom: 0;
		right: 0;
		overflow-y: auto;
		overflow-x: auto;
		-webkit-overflow-scrolling: touch;
		margin: 0 0 0 -42px;
		padding: 71px 0 28px 42px;
	}html[dir="rtl"] .tc-sidebar-scrollable {
		left: auto;
		right: 770px;
	}.tc-story-river {
		position: relative;
		left: 0px;
		top: 0px;
		
/* Changed!!! */
		width: 1170px;
		padding: 42px 42px 42px 42px;
	}}@media print {body.tc-body {
		background-color: transparent;
	}.tc-sidebar-header, .tc-topbar {
		display: none;
	}.tc-story-river {
		margin: 0;
		padding: 0;
	}.tc-story-river .tc-tiddler-frame {
		margin: 0;
		border: none;
		padding: 0;
	}
}/*
** Tiddler styles
*/.tc-tiddler-frame {
	position: relative;
	margin-bottom: 28px;
	background-color: #ffffff;
	border: 1px solid #ffffff;
}
.tc-tiddler-info {
	padding: 14px 42px 14px 42px;
	background-color: #f8f8f8;
	border-top: 1px solid #dddddd;
	border-bottom: 1px solid #dddddd;
}.tc-tiddler-info p {
	margin-top: 3px;
	margin-bottom: 3px;
}.tc-tiddler-info .tc-tab-buttons button.tc-tab-selected {
	background-color: #f8f8f8;
	border-bottom: 1px solid #f8f8f8;
}.tc-view-field-table {
	width: 100%;
}.tc-view-field-name {
	width: 1%; /* Makes this column be as narrow as possible */
	text-align: right;
	font-style: italic;
	font-weight: 200;
}.tc-view-field-value {
}@media (max-width: 960px) {
	.tc-tiddler-frame {
		padding: 14px 14px 14px 14px;
	}.tc-tiddler-info {
		margin: 0 -14px 0 -14px;
	}
}@media (min-width: 960px) {
	.tc-tiddler-frame {
		padding: 28px 42px 42px 42px;

/* Changed!!! */
		width: 1086px;
		border-radius: 2px;
	}.tc-tiddler-info {
		margin: 0 -42px 0 -42px;
	}
}.tc-site-title,
.tc-titlebar {
	font-weight: 300;
	font-size: 2.35em;
	line-height: 1.2em;
	color: #182955;
	margin: 0;
}.tc-site-title {
	color: #182955;
}.tc-tiddler-title-icon {
	vertical-align: middle;
}.tc-system-title-prefix {
	color: #bbb;
}.tc-titlebar h2 {
	font-size: 1em;
	display: inline;
}.tc-titlebar img {
	height: 1em;
}.tc-subtitle {
	font-size: 0.9em;
	color: #c0c0c0;
	font-weight: 300;
}.tc-tiddler-missing .tc-title {
  font-style: italic;
  font-weight: normal;
}.tc-tiddler-frame .tc-tiddler-controls {
	float: right;
}.tc-tiddler-controls .tc-drop-down {
	font-size: 0.6em;
}.tc-tiddler-controls .tc-drop-down .tc-drop-down {
	font-size: 1em;
}.tc-tiddler-controls > span > button,
.tc-tiddler-controls > span > span > button,
.tc-tiddler-controls > span > span > span > button {
	vertical-align: baseline;
	margin-left:5px;
}.tc-tiddler-controls button svg, .tc-tiddler-controls button img,
.tc-search button svg, .tc-search a svg {
	fill: #cccccc;
}.tc-tiddler-controls button svg, .tc-tiddler-controls button img {
	height: 0.75em;
}.tc-search button svg, .tc-search a svg {
    height: 1.2em;
    width: 1.2em;
    margin: 0 0.25em;
}.tc-tiddler-controls button.tc-selected svg,
.tc-page-controls button.tc-selected svg  {
	fill: #444444;
}.tc-tiddler-controls button.tc-btn-invisible:hover svg,
.tc-search button:hover svg, .tc-search a:hover svg {
	fill: #888888;
}@media print {
	.tc-tiddler-controls {
		display: none;
	}
}.tc-tiddler-help { /* Help prompts within tiddler template */
	color: #bbb;
	margin-top: 14px;
}.tc-tiddler-help a.tc-tiddlylink {
	color: #888888;
}.tc-tiddler-frame .tc-edit-texteditor {
	width: 100%;
	margin: 4px 0 4px 0;
}.tc-tiddler-frame input.tc-edit-texteditor,
.tc-tiddler-frame textarea.tc-edit-texteditor,
.tc-tiddler-frame iframe.tc-edit-texteditor {
	padding: 3px 3px 3px 3px;
	border: 1px solid #cccccc;
	background-color: #f8f8f8;
	line-height: 1.3em;
	-webkit-appearance: none;
	font-family: ;
}.tc-tiddler-frame .tc-binary-warning {
	width: 100%;
	height: 5em;
	text-align: center;
	padding: 3em 3em 6em 3em;
	background: #ffe476;
	border: 1px solid #b99e2f;
}canvas.tc-edit-bitmapeditor  {
	border: 6px solid #ffffff;
	cursor: crosshair;
	-moz-user-select: none;
	-webkit-user-select: none;
	-ms-user-select: none;
	margin-top: 6px;
	margin-bottom: 6px;
}.tc-edit-bitmapeditor-width {
	display: block;
}.tc-edit-bitmapeditor-height {
	display: block;
}.tc-tiddler-body {
	clear: both;
}.tc-tiddler-frame .tc-tiddler-body {
/** Changed **/
	font-size: 22px;
	line-height: 28px;
}.tc-titlebar, .tc-tiddler-edit-title {
	overflow: hidden; /* https://github.com/Jermolene/TiddlyWiki5/issues/282 */
}html body.tc-body.tc-single-tiddler-window {
	margin: 1em;
	background: #ffffff;
}.tc-single-tiddler-window img,
.tc-single-tiddler-window svg,
.tc-single-tiddler-window canvas,
.tc-single-tiddler-window embed,
.tc-single-tiddler-window iframe {
	max-width: 100%;
}/*
** Editor
*/.tc-editor-toolbar {
	margin-top: 8px;
}.tc-editor-toolbar button {
	vertical-align: middle;
	background-color: #cccccc;
	fill: #444444;
	border-radius: 4px;
	padding: 3px;
	margin: 2px 0 2px 4px;
}.tc-editor-toolbar button.tc-text-editor-toolbar-item-adjunct {
	margin-left: 1px;
	width: 1em;
	border-radius: 8px;
}.tc-editor-toolbar button.tc-text-editor-toolbar-item-start-group {
	margin-left: 11px;
}.tc-editor-toolbar button.tc-selected {
	background-color: #5778d8;
}.tc-editor-toolbar button svg {
	width: 1.6em;
	height: 1.2em;
}.tc-editor-toolbar button:hover {
	background-color: #444444;
	fill: #ffffff;
	color: #ffffff;
}.tc-editor-toolbar .tc-text-editor-toolbar-more {
	white-space: normal;
}.tc-editor-toolbar .tc-text-editor-toolbar-more button {
	display: inline-block;
	padding: 3px;
	width: auto;
}.tc-editor-toolbar .tc-search-results {
	padding: 0;
}/*
** Adjustments for fluid-fixed mode
*/@media (min-width: 960px) {}/*
** Toolbar buttons
*/.tc-page-controls svg.tc-image-new-button {
  fill: ;
}.tc-page-controls svg.tc-image-options-button {
  fill: ;
}.tc-page-controls svg.tc-image-save-button {
  fill: ;
}.tc-tiddler-controls button svg.tc-image-info-button {
  fill: ;
}.tc-tiddler-controls button svg.tc-image-edit-button {
  fill: ;
}.tc-tiddler-controls button svg.tc-image-close-button {
  fill: ;
}.tc-tiddler-controls button svg.tc-image-delete-button {
  fill: ;
}.tc-tiddler-controls button svg.tc-image-cancel-button {
  fill: ;
}.tc-tiddler-controls button svg.tc-image-done-button {
  fill: ;
}/*
** Tiddler edit mode
*/.tc-tiddler-edit-frame em.tc-edit {
	color: #bbb;
	font-style: normal;
}.tc-edit-type-dropdown a.tc-tiddlylink-missing {
	font-style: normal;
}.tc-edit-tags {
	border: 1px solid #cccccc;
	padding: 4px 8px 4px 8px;
}.tc-edit-add-tag {
	display: inline-block;
}.tc-edit-add-tag .tc-add-tag-name input {
	width: 50%;
}.tc-edit-add-tag .tc-keyboard {
	display:inline;
}.tc-edit-tags .tc-tag-label {
	display: inline-block;
}.tc-edit-tags-list {
	margin: 14px 0 14px 0;
}.tc-remove-tag-button {
	padding-left: 4px;
}.tc-tiddler-preview {
	overflow: auto;
}.tc-tiddler-preview-preview {
	float: right;
	width: 49%;
	border: 1px solid #cccccc;
	margin: 4px 0 3px 3px;
	padding: 3px 3px 3px 3px;
}.tc-tiddler-frame .tc-tiddler-preview .tc-edit-texteditor {
	width: 49%;
}.tc-tiddler-frame .tc-tiddler-preview canvas.tc-edit-bitmapeditor {
	max-width: 49%;
}.tc-edit-fields {
	width: 100%;
}.tc-edit-fields table, .tc-edit-fields tr, .tc-edit-fields td {
	border: none;
	padding: 4px;
}.tc-edit-fields > tbody > .tc-edit-field:nth-child(odd) {
	background-color: #f0f4f0;
}.tc-edit-fields > tbody > .tc-edit-field:nth-child(even) {
	background-color: #e0e8e0;
}.tc-edit-field-name {
	text-align: right;
}.tc-edit-field-value input {
	width: 100%;
}.tc-edit-field-remove {
}.tc-edit-field-remove svg {
	height: 1em;
	width: 1em;
	fill: #bbb;
	vertical-align: middle;
}.tc-edit-field-add-name {
	display: inline-block;
	width: 15%;
}.tc-edit-field-add-value {
	display: inline-block;
	width: 40%;
}.tc-edit-field-add-button {
	display: inline-block;
	width: 10%;
}/*
** Storyview Classes
*/.tc-storyview-zoomin-tiddler {
	position: absolute;
	display: block;
	width: 100%;
}@media (min-width: 960px) {.tc-storyview-zoomin-tiddler {
		width: calc(100% - 84px);
	}}/*
** Dropdowns
*/.tc-btn-dropdown {
	text-align: left;
}.tc-btn-dropdown svg, .tc-btn-dropdown img {
	height: 1em;
	width: 1em;
	fill: #bbb;
}.tc-drop-down-wrapper {
	position: relative;
}.tc-drop-down {
	min-width: 380px;
	border: 1px solid #bbb;
	background-color: #ffffff;
	padding: 7px 0 7px 0;
	margin: 4px 0 0 0;
	white-space: nowrap;
	text-shadow: none;
	line-height: 1.4;
}.tc-drop-down .tc-drop-down {
	margin-left: 14px;
}.tc-drop-down button svg, .tc-drop-down a svg  {
	fill: #333333;
}.tc-drop-down button.tc-btn-invisible:hover svg {
	fill: #333333;
}.tc-drop-down p {
	padding: 0 14px 0 14px;
}.tc-drop-down svg {
	width: 1em;
	height: 1em;
}.tc-drop-down img {
	width: 1em;
}.tc-drop-down a, .tc-drop-down button {
	display: block;
	padding: 0 14px 0 14px;
	width: 100%;
	text-align: left;
	color: #333333;
	line-height: 1.4;
}.tc-drop-down .tc-tab-set .tc-tab-buttons button {
	display: inline-block;
    width: auto;
    margin-bottom: 0px;
    border-bottom-left-radius: 0;
    border-bottom-right-radius: 0;
}.tc-drop-down .tc-prompt {
	padding: 0 14px;
}.tc-drop-down .tc-chooser {
	border: none;
}.tc-drop-down .tc-chooser .tc-swatches-horiz {
	font-size: 0.4em;
	padding-left: 1.2em;
}.tc-drop-down .tc-file-input-wrapper {
	width: 100%;
}.tc-drop-down .tc-file-input-wrapper button {
	color: #333333;
}.tc-drop-down a:hover, .tc-drop-down button:hover, .tc-drop-down .tc-file-input-wrapper:hover button {
	color: #ffffff;
	background-color: #5778d8;
	text-decoration: none;
}.tc-drop-down .tc-tab-buttons button {
	background-color: #ececec;
}.tc-drop-down .tc-tab-buttons button.tc-tab-selected {
	background-color: #fff;
	border-bottom: 1px solid #fff;
}.tc-drop-down-bullet {
	display: inline-block;
	width: 0.5em;
}.tc-drop-down .tc-tab-contents a {
	padding: 0 0.5em 0 0.5em;
}.tc-block-dropdown-wrapper {
	position: relative;
}.tc-block-dropdown {
	position: absolute;
	min-width: 220px;
	border: 1px solid #bbb;
	background-color: #ffffff;
	padding: 7px 0;
	margin: 4px 0 0 0;
	white-space: nowrap;
	z-index: 1000;
	text-shadow: none;
}.tc-block-dropdown.tc-search-drop-down {
	margin-left: -12px;
}.tc-block-dropdown a {
	display: block;
	padding: 4px 14px 4px 14px;
}.tc-block-dropdown.tc-search-drop-down a {
	display: block;
	padding: 0px 10px 0px 10px;
}.tc-drop-down .tc-dropdown-item-plain,
.tc-block-dropdown .tc-dropdown-item-plain {
	padding: 4px 14px 4px 7px;
}.tc-drop-down .tc-dropdown-item,
.tc-block-dropdown .tc-dropdown-item {
	padding: 4px 14px 4px 7px;
	color: #bbb;
}.tc-block-dropdown a:hover {
	color: #ffffff;
	background-color: #5778d8;
	text-decoration: none;
}.tc-search-results {
	padding: 0 7px 0 7px;
}.tc-image-chooser, .tc-colour-chooser {
	white-space: normal;
}.tc-image-chooser a,
.tc-colour-chooser a {
	display: inline-block;
	vertical-align: top;
	text-align: center;
	position: relative;
}.tc-image-chooser a {
	border: 1px solid #bbb;
	padding: 2px;
	margin: 2px;
	width: 4em;
	height: 4em;
}.tc-colour-chooser a {
	padding: 3px;
	width: 2em;
	height: 2em;
	vertical-align: middle;
}.tc-image-chooser a:hover,
.tc-colour-chooser a:hover {
	background: #5778d8;
	padding: 0px;
	border: 3px solid #5778d8;
}.tc-image-chooser a svg,
.tc-image-chooser a img {
	display: inline-block;
	width: auto;
	height: auto;
	max-width: 3.5em;
	max-height: 3.5em;
	position: absolute;
	top: 0;
	bottom: 0;
	left: 0;
	right: 0;
	margin: auto;
}/*
** Modals
*/.tc-modal-wrapper {
	position: fixed;
	overflow: auto;
	overflow-y: scroll;
	top: 0;
	right: 0;
	bottom: 0;
	left: 0;
	z-index: 900;
}.tc-modal-backdrop {
	position: fixed;
	top: 0;
	right: 0;
	bottom: 0;
	left: 0;
	z-index: 1000;
	background-color: #333333;
}.tc-modal {
	z-index: 1100;
	background-color: #ffffff;
	border: 1px solid #999999;
}@media (max-width: 55em) {
	.tc-modal {
		position: fixed;
		top: 1em;
		left: 1em;
		right: 1em;
	}.tc-modal-body {
		overflow-y: auto;
		max-height: 400px;
		max-height: 60vh;
	}
}@media (min-width: 55em) {
	.tc-modal {
		position: fixed;
		top: 2em;
		left: 25%;
		width: 50%;
	}.tc-modal-body {
		overflow-y: auto;
		max-height: 400px;
		max-height: 60vh;
	}
}.tc-modal-header {
	padding: 9px 15px;
	border-bottom: 1px solid #eeeeee;
}.tc-modal-header h3 {
	margin: 0;
	line-height: 30px;
}.tc-modal-header img, .tc-modal-header svg {
	width: 1em;
	height: 1em;
}.tc-modal-body {
	padding: 15px;
}.tc-modal-footer {
	padding: 14px 15px 15px;
	margin-bottom: 0;
	text-align: right;
	background-color: #f5f5f5;
	border-top: 1px solid #dddddd;
}/*
** Notifications
*/.tc-notification {
	position: fixed;
	top: 14px;
	right: 42px;
	z-index: 1300;
	max-width: 280px;
	padding: 0 14px 0 14px;
	background-color: #ffffdd;
	border: 1px solid #999999;
}/*
** Tabs
*/.tc-tab-set.tc-vertical {
	display: -webkit-flex;
	display: flex;
}.tc-tab-buttons {
	font-size: 0.85em;
	padding-top: 1em;
	margin-bottom: -2px;
}.tc-tab-buttons.tc-vertical  {
	z-index: 100;
	display: block;
	padding-top: 14px;
	vertical-align: top;
	text-align: right;
	margin-bottom: inherit;
	margin-right: -1px;
	max-width: 33%;
	-webkit-flex: 0 0 auto;
	flex: 0 0 auto;
}.tc-tab-buttons button.tc-tab-selected {
	color: #666666;
	background-color: #ffffff;
	border-left: 1px solid #d8d8d8;
	border-top: 1px solid #d8d8d8;
	border-right: 1px solid #d8d8d8;
}.tc-tab-buttons button {
	color: #666666;
	padding: 3px 5px 3px 5px;
	margin-right: 0.3em;
	font-weight: 300;
	border: none;
	background: inherit;
	background-color: #d8d8d8;
	border-left: 1px solid #cccccc;
	border-top: 1px solid #cccccc;
	border-right: 1px solid #cccccc;
	border-top-left-radius: 2px;
	border-top-right-radius: 2px;
	border-bottom-left-radius: 0;
	border-bottom-right-radius: 0;
}.tc-tab-buttons.tc-vertical button {
	display: block;
	width: 100%;
	margin-top: 3px;
	margin-right: 0;
	text-align: right;
	background-color: #d8d8d8;
	border-left: 1px solid #cccccc;
	border-bottom: 1px solid #cccccc;
	border-right: none;
	border-top-left-radius: 2px;
	border-bottom-left-radius: 2px;
	border-top-right-radius: 0;
	border-bottom-right-radius: 0;
}.tc-tab-buttons.tc-vertical button.tc-tab-selected {
	background-color: #ffffff;
	border-right: 1px solid #ffffff;
}.tc-tab-divider {
	border-top: 1px solid #d8d8d8;
}.tc-tab-divider.tc-vertical  {
	display: none;
}.tc-tab-content {
	margin-top: 14px;
}.tc-tab-content.tc-vertical  {
    word-break: break-word;
	display: inline-block;
	vertical-align: top;
	padding-top: 0;
	padding-left: 14px;
	border-left: 1px solid #cccccc;
	-webkit-flex: 1 0 70%;
	flex: 1 0 70%;
}.tc-sidebar-lists .tc-tab-buttons {
	margin-bottom: -1px;
}.tc-sidebar-lists .tc-tab-buttons button.tc-tab-selected {
	background-color: #f4f4f4;
	color: ;
	border-left: 1px solid #d8d8d8;
	border-top: 1px solid #d8d8d8;
	border-right: 1px solid #d8d8d8;
}.tc-sidebar-lists .tc-tab-buttons button {
	background-color: #e0e0e0;
	color: #666666;
	border-left: 1px solid #cccccc;
	border-top: 1px solid #cccccc;
	border-right: 1px solid #cccccc;
}.tc-sidebar-lists .tc-tab-divider {
	border-top: 1px solid #e4e4e4;
}.tc-more-sidebar > .tc-tab-set > .tc-tab-buttons > button {
	display: block;
	width: 100%;
	background-color: #e0e0e0;
	border-top: none;
	border-left: none;
	border-bottom: none;
	border-right: 1px solid #ccc;
	margin-bottom: inherit;
}.tc-more-sidebar > .tc-tab-set > .tc-tab-buttons > button.tc-tab-selected {
	background-color: #f4f4f4;
	border: none;
}/*
** Manager
*/.tc-manager-wrapper {
	
}.tc-manager-controls {
	
}.tc-manager-control {
	margin: 0.5em 0;
}.tc-manager-list {
	width: 100%;
	border-top: 1px solid #bbb;
	border-left: 1px solid #bbb;
	border-right: 1px solid #bbb;
}.tc-manager-list-item {}.tc-manager-list-item-heading {
    display: block;
    width: 100%;
    text-align: left;	
	border-bottom: 1px solid #bbb;
	padding: 3px;
}.tc-manager-list-item-heading-selected {
	font-weight: bold;
	color: #ffffff;
	fill: #ffffff;
	background-color: #333333;
}.tc-manager-list-item-heading:hover {
	background: #5778d8;
	color: #ffffff;
}.tc-manager-list-item-content {
	display: flex;
}.tc-manager-list-item-content-sidebar {
    flex: 1 0;
    background: #f8f8f8;
    border-right: 0.5em solid #bbb;
    border-bottom: 0.5em solid #bbb;
    white-space: nowrap;
}.tc-manager-list-item-content-item-heading {
	display: block;
	width: 100%;
	text-align: left;
    background: #bbb;
	text-transform: uppercase;
	font-size: 0.6em;
	font-weight: bold;
    padding: 0.5em 0 0.5em 0;
}.tc-manager-list-item-content-item-body {
	padding: 0 0.5em 0 0.5em;
}.tc-manager-list-item-content-item-body > pre {
	margin: 0.5em 0 0.5em 0;
	border: none;
	background: inherit;
}.tc-manager-list-item-content-tiddler {
    flex: 3 1;
    border-left: 0.5em solid #bbb;
    border-right: 0.5em solid #bbb;
    border-bottom: 0.5em solid #bbb;
}.tc-manager-list-item-content-item-body > table {
	border: none;
	padding: 0;
	margin: 0;
}.tc-manager-list-item-content-item-body > table td {
	border: none;
}.tc-manager-icon-editor > button {
	width: 100%;
}.tc-manager-icon-editor > button > svg,
.tc-manager-icon-editor > button > button {
	width: 100%;
	height: auto;
}/*
** Alerts
*/.tc-alerts {
	position: fixed;
	top: 0;
	left: 0;
	max-width: 500px;
	z-index: 20000;
}.tc-alert {
	position: relative;
	margin: 28px;
	padding: 14px 14px 14px 14px;
	border: 2px solid #b99e2f;
	background-color: #ffe476;
}.tc-alert-toolbar {
	position: absolute;
	top: 14px;
	right: 14px;
}.tc-alert-toolbar svg {
	fill: #b99e2f;
}.tc-alert-subtitle {
	color: #b99e2f;
	font-weight: bold;
}.tc-alert-highlight {
	color: #881122;
}@media (min-width: 960px) {.tc-static-alert {
		position: relative;
	}.tc-static-alert-inner {
		position: absolute;
		z-index: 100;
	}}.tc-static-alert-inner {
	padding: 0 2px 2px 42px;
	color: #aaaaaa;
}/*
** Floating drafts list
*/.tc-drafts-list {
	z-index: 2000;
	position: fixed;
	font-size: 0.8em;
	left: 0;
	bottom: 0;
}.tc-drafts-list a {
	margin: 0 0.5em;
	padding: 4px 4px;
	border-top-left-radius: 4px;
	border-top-right-radius: 4px;
	border: 1px solid #ffffff;
	border-bottom-none;
	background: #ff0000;
	color: #ffffff;
	fill: #ffffff;
}.tc-drafts-list a:hover {
	text-decoration: none;
	background: #333333;
	color: #ffffff;
	fill: #ffffff;
}.tc-drafts-list a svg {
	width: 1em;
	height: 1em;
	vertical-align: text-bottom;
}/*
** Control panel
*/.tc-control-panel td {
	padding: 4px;
}.tc-control-panel table, .tc-control-panel table input, .tc-control-panel table textarea {
	width: 100%;
}.tc-plugin-info {
	display: block;
	border: 1px solid #bbb;
	background-colour: #ffffff;
	margin: 0.5em 0 0.5em 0;
	padding: 4px;
}.tc-plugin-info-disabled {
	background: -webkit-repeating-linear-gradient(45deg, #ff0, #ff0 10px, #eee 10px, #eee 20px);
	background: repeating-linear-gradient(45deg, #ff0, #ff0 10px, #eee 10px, #eee 20px);
}.tc-plugin-info-disabled:hover {
	background: -webkit-repeating-linear-gradient(45deg, #aa0, #aa0 10px, #888 10px, #888 20px);
	background: repeating-linear-gradient(45deg, #aa0, #aa0 10px, #888 10px, #888 20px);
}a.tc-tiddlylink.tc-plugin-info:hover {
	text-decoration: none;
	background-color: #5778d8;
	color: #ffffff;
	fill: #333333;
}a.tc-tiddlylink.tc-plugin-info:hover .tc-plugin-info > .tc-plugin-info-chunk > svg {
	fill: #333333;
}.tc-plugin-info-chunk {
	display: inline-block;
	vertical-align: middle;
}.tc-plugin-info-chunk h1 {
	font-size: 1em;
	margin: 2px 0 2px 0;
}.tc-plugin-info-chunk h2 {
	font-size: 0.8em;
	margin: 2px 0 2px 0;
}.tc-plugin-info-chunk div {
	font-size: 0.7em;
	margin: 2px 0 2px 0;
}.tc-plugin-info:hover > .tc-plugin-info-chunk > img, .tc-plugin-info:hover > .tc-plugin-info-chunk > svg {
	width: 2em;
	height: 2em;
	fill: #333333;
}.tc-plugin-info > .tc-plugin-info-chunk > img, .tc-plugin-info > .tc-plugin-info-chunk > svg {
	width: 2em;
	height: 2em;
	fill: #bbb;
}.tc-plugin-info.tc-small-icon > .tc-plugin-info-chunk > img, .tc-plugin-info.tc-small-icon > .tc-plugin-info-chunk > svg {
	width: 1em;
	height: 1em;
}.tc-plugin-info-dropdown {
	border: 1px solid #bbb;
	margin-top: -8px;
}.tc-plugin-info-dropdown-message {
	background: #ecf2ff;
	padding: 0.5em 1em 0.5em 1em;
	font-weight: bold;
	font-size: 0.8em;
}.tc-plugin-info-dropdown-body {
	padding: 1em 1em 1em 1em;
}.tc-check-list {
	line-height: 2em;
}.tc-check-list .tc-image-button {
	height: 1.5em;
}/*
** Message boxes
*/.tc-message-box {
	border: 1px solid #cfd6e6;
	background: #ecf2ff;
	padding: 0px 21px 0px 21px;
	font-size: 12px;
	line-height: 18px;
	color: #547599;
}.tc-message-box svg {
	width: 1em;
	height: 1em;
    vertical-align: text-bottom;
}/*
** Pictures
*/.tc-bordered-image {
	border: 1px solid #bbb;
	padding: 5px;
	margin: 5px;
}/*
** Floats
*/.tc-float-right {
	float: right;
}/*
** Chooser
*/.tc-chooser {
	border-right: 1px solid #f0f0f0;
	border-left: 1px solid #f0f0f0;
}.tc-chooser-item {
	border-bottom: 1px solid #f0f0f0;
	border-top: 1px solid #f0f0f0;
	padding: 2px 4px 2px 14px;
}.tc-drop-down .tc-chooser-item {
	padding: 2px;
}.tc-chosen,
.tc-chooser-item:hover {
	background-color: #f0f0f0;
	border-color: #a8a8a8;
}.tc-chosen .tc-tiddlylink {
	cursor:default;
}.tc-chooser-item .tc-tiddlylink {
	display: block;
	text-decoration: none;
	background-color: transparent;
}.tc-chooser-item:hover .tc-tiddlylink:hover {
	text-decoration: none;
}.tc-drop-down .tc-chosen .tc-tiddlylink,
.tc-drop-down .tc-chooser-item .tc-tiddlylink:hover {
	color: #333333;
}.tc-chosen > .tc-tiddlylink:before {
	margin-left: -10px;
	position: relative;
	content: "» ";
}.tc-chooser-item svg,
.tc-chooser-item img{
	width: 1em;
	height: 1em;
	vertical-align: middle;
}.tc-language-chooser .tc-image-button img {
	width: 2em;
	vertical-align: -0.15em;
}/*
** Palette swatches
*/.tc-swatches-horiz {
}.tc-swatches-horiz .tc-swatch {
	display: inline-block;
}.tc-swatch {
	width: 2em;
	height: 2em;
	margin: 0.4em;
	border: 1px solid #888;
}/*
** Table of contents
*/.tc-sidebar-lists .tc-table-of-contents {
	white-space: nowrap;
}.tc-table-of-contents button {
	color: #acacac;
}.tc-table-of-contents svg {
	width: 0.7em;
	height: 0.7em;
	vertical-align: middle;
	fill: #acacac;
}.tc-table-of-contents ol {
	list-style-type: none;
	padding-left: 0;
}.tc-table-of-contents ol ol {
	padding-left: 1em;
}.tc-table-of-contents li {
	font-size: 1.0em;
	font-weight: bold;
}.tc-table-of-contents li a {
	font-weight: bold;
}.tc-table-of-contents li li {
	font-size: 0.95em;
	font-weight: normal;
	line-height: 1.4;
}.tc-table-of-contents li li a {
	font-weight: normal;
}.tc-table-of-contents li li li {
	font-size: 0.95em;
	font-weight: 200;
	line-height: 1.5;
}.tc-table-of-contents li li li li {
	font-size: 0.95em;
	font-weight: 200;
}.tc-tabbed-table-of-contents {
	display: -webkit-flex;
	display: flex;
}.tc-tabbed-table-of-contents .tc-table-of-contents {
	z-index: 100;
	display: inline-block;
	padding-left: 1em;
	max-width: 50%;
	-webkit-flex: 0 0 auto;
	flex: 0 0 auto;
	background: #d8d8d8;
	border-left: 1px solid #cccccc;
	border-top: 1px solid #cccccc;
	border-bottom: 1px solid #cccccc;
}.tc-tabbed-table-of-contents .tc-table-of-contents .toc-item > a,
.tc-tabbed-table-of-contents .tc-table-of-contents .toc-item-selected > a {
	display: block;
	padding: 0.12em 1em 0.12em 0.25em;
}.tc-tabbed-table-of-contents .tc-table-of-contents .toc-item > a {
	border-top: 1px solid #d8d8d8;
	border-left: 1px solid #d8d8d8;
	border-bottom: 1px solid #d8d8d8;
}.tc-tabbed-table-of-contents .tc-table-of-contents .toc-item > a:hover {
	text-decoration: none;
	border-top: 1px solid #cccccc;
	border-left: 1px solid #cccccc;
	border-bottom: 1px solid #cccccc;
	background: #cccccc;
}.tc-tabbed-table-of-contents .tc-table-of-contents .toc-item-selected > a {
	border-top: 1px solid #cccccc;
	border-left: 1px solid #cccccc;
	border-bottom: 1px solid #cccccc;
	background: #ffffff;
	margin-right: -1px;
}.tc-tabbed-table-of-contents .tc-table-of-contents .toc-item-selected > a:hover {
	text-decoration: none;
}.tc-tabbed-table-of-contents .tc-tabbed-table-of-contents-content {
	display: inline-block;
	vertical-align: top;
	padding-left: 1.5em;
	padding-right: 1.5em;
	border: 1px solid #cccccc;
	-webkit-flex: 1 0 50%;
	flex: 1 0 50%;
}/*
** Dirty indicator
*/body.tc-dirty span.tc-dirty-indicator, body.tc-dirty span.tc-dirty-indicator svg {
	fill: #ff0000;
	color: #ff0000;
}/*
** File inputs
*/.tc-file-input-wrapper {
	position: relative;
	overflow: hidden;
	display: inline-block;
	vertical-align: middle;
}.tc-file-input-wrapper input[type=file] {
	position: absolute;
	top: 0;
	left: 0;
	right: 0;
	bottom: 0;
	font-size: 999px;
	max-width: 100%;
	max-height: 100%;
	filter: alpha(opacity=0);
	opacity: 0;
	outline: none;
	background: white;
	cursor: pointer;
	display: inline-block;
}/*
** Thumbnail macros
*/.tc-thumbnail-wrapper {
	position: relative;
	display: inline-block;
	margin: 6px;
	vertical-align: top;
}.tc-thumbnail-right-wrapper {
	float:right;
	margin: 0.5em 0 0.5em 0.5em;
}.tc-thumbnail-image {
	text-align: center;
	overflow: hidden;
	border-radius: 3px;
}.tc-thumbnail-image svg,
.tc-thumbnail-image img {
	filter: alpha(opacity=1);
	opacity: 1;
	min-width: 100%;
	min-height: 100%;
	max-width: 100%;
}.tc-thumbnail-wrapper:hover .tc-thumbnail-image svg,
.tc-thumbnail-wrapper:hover .tc-thumbnail-image img {
	filter: alpha(opacity=0.8);
	opacity: 0.8;
}.tc-thumbnail-background {
	position: absolute;
	border-radius: 3px;
}.tc-thumbnail-icon svg,
.tc-thumbnail-icon img {
	width: 3em;
	height: 3em;
	
  -webkit-filter: drop-shadow(2px 2px 4px rgba(0,0,0,0.3));
     -moz-filter: drop-shadow(2px 2px 4px rgba(0,0,0,0.3));
          filter: drop-shadow(2px 2px 4px rgba(0,0,0,0.3));

}.tc-thumbnail-wrapper:hover .tc-thumbnail-icon svg,
.tc-thumbnail-wrapper:hover .tc-thumbnail-icon img {
	fill: #fff;
	
  -webkit-filter: drop-shadow(3px 3px 4px rgba(0,0,0,0.6));
     -moz-filter: drop-shadow(3px 3px 4px rgba(0,0,0,0.6));
          filter: drop-shadow(3px 3px 4px rgba(0,0,0,0.6));

}.tc-thumbnail-icon {
	position: absolute;
	top: 0;
	left: 0;
	right: 0;
	bottom: 0;
	display: -webkit-flex;
	-webkit-align-items: center;
	-webkit-justify-content: center;
	display: flex;
	align-items: center;
	justify-content: center;
}.tc-thumbnail-caption {
	position: absolute;
	background-color: #777;
	color: #fff;
	text-align: center;
	bottom: 0;
	width: 100%;
	filter: alpha(opacity=0.9);
	opacity: 0.9;
	line-height: 1.4;
	border-bottom-left-radius: 3px;
	border-bottom-right-radius: 3px;
}.tc-thumbnail-wrapper:hover .tc-thumbnail-caption {
	filter: alpha(opacity=1);
	opacity: 1;
}/*
** Diffs
*/.tc-diff-equal {
	background-color: ;
	color: #333333;
}.tc-diff-insert {
	background-color: #aaefad;
	color: #333333;
}.tc-diff-delete {
	background-color: #ffc9c9;
	color: #333333;
}.tc-diff-invisible {
	background-color: ;
	color: #bbb;
}.tc-diff-tiddlers th {
	text-align: right;
	background: #ffffff;
	font-weight: normal;
	font-style: italic;
}.tc-diff-tiddlers pre {
    margin: 0;
    padding: 0;
    border: none;
    background: none;
}/*
** Errors
*/.tc-error {
	background: #f00;
	color: #fff;
}/*
** Tree macro
*/.tc-tree div {
    	padding-left: 14px;
}.tc-tree ol {
    	list-style-type: none;
    	padding-left: 0;
    	margin-top: 0;
}.tc-tree ol ol {
    	padding-left: 1em;    
}.tc-tree button { 
    	color: #acacac;
}.tc-tree svg {
     	fill: #acacac;
}.tc-tree span svg {
    	width: 1em;
    	height: 1em;
    	vertical-align: baseline;
}.tc-tree li span {
    	color: lightgray;
}select {
        color: ;
        background: ;
}

@media (min-width: 960px) {html .tc-page-container {
		text-align: center;
	}html .tc-story-river {
		position: relative;
		
/* Changed!! */
		/*width: 770px;*/
		padding: 42px;
		margin: 0 auto;
		text-align: left;
	}html .tc-sidebar-scrollable {
		text-align: left;
		left: 50%;
		right: 0;
		margin-left: 343px;
	}
}



</style>
</head>
<body class="tc-body">



<section class="tc-story-river">`;
}

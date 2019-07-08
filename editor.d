import arsd.cgi;
import std.conv, std.file, std.process, std.stdio, std.string;

string[] deps = import("dependencies.txt").split("\n##file##\n");
enum img = import("menu.png");

void app(Cgi cgi) {
	string[string] dep;
	dep["asciidoc.js"] = deps[0];
	dep["creole.js"] = deps[1];
	dep["custom.css"] = deps[2];
	dep["dialog.css"] = deps[3];
	dep["editor.css"] = deps[4];
	dep["gollum.css"] = deps[5];
	dep["gollum.dialog.js"] = deps[6];
	dep["gollum.editor.js"] = deps[7];
	dep["gollum.js"] = deps[8];
	dep["gollum.placeholder.js"] = deps[9];
	dep["jquery-1.7.2.min.js"] = deps[10];
	dep["markdown.js"] = deps[11];
	dep["mousetrap.min.js"] = deps[12];
	dep["org.js"] = deps[13];
	dep["pod.js"] = deps[14];
	dep["print.css"] = deps[15];
	dep["rdoc.js"] = deps[16];
	dep["template.css"] = deps[17];
	dep["textile.js"] = deps[18];

  cgi.setResponseContentType("text/html");
  string path = cgi.pathInfo;
  if (path.endsWith(".css")) {
		cgi.setResponseContentType("text/css");
	}
	if (path.endsWith(".js")) {
		cgi.setResponseContentType("text/javascript");
	}
  string data;
  switch(path) {
		case "/edit":
			data = editor(cgi.get["file"]);
			break;
		case "/save":
			std.file.write(cgi.post["file"], cgi.post["content"]);
			cgi.setResponseLocation("/view?file=" ~ cgi.post["file"]);
			break;
		case "/view":
			string cmd = "pandoc -s " ~ cgi.get["file"] ~ " -t html --quiet";
			data = "You're viewing an unstyled preview of " ~ cgi.get["file"] ~ "<br><br>\n" ~ 
				executeShell(cmd).output ~ `<br><br><a href="/edit?file=` ~
				cgi.get["file"] ~ `">Edit</a>`;
			break;
		case "/icon-sprite.png":
			data = img.to!string;
			break;
		default:
			if (path[1..$] in dep) {
				data = dep[path[1..$]];
			} else {
				data = "I don't know that page";
			}
			break;
	}
  cgi.write(data, true);
}
mixin GenericMain!app;

string editor(string fn) {
	string txt;
	string action = "Creating ";
	if (exists(fn)) {
		txt = readText(fn);
		action = "Editing ";
	}
	return `
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-type" content="text/html;charset=utf-8">
  <meta name="MobileOptimized" content="width">
  <meta name="HandheldFriendly" content="true">
  <meta name="viewport" content="width=device-width">
  <link rel="stylesheet" type="text/css" href="gollum.css" media="all">
  <link rel="stylesheet" type="text/css" href="editor.css" media="all">
  <link rel="stylesheet" type="text/css" href="dialog.css" media="all">
  <link rel="stylesheet" type="text/css" href="template.css" media="all">
  <link rel="stylesheet" type="text/css" href="print.css" media="print">
  
  <script>
      var baseUrl = '';
      var uploadDest   = '';
      var pageFullPath = '';
  </script>
  <script type="text/javascript" src="jquery-1.7.2.min.js"></script>
  <script type="text/javascript" src="mousetrap.min.js"></script>
  <script type="text/javascript" src="gollum.js"></script>
  <script type="text/javascript" src="gollum.dialog.js"></script>
  <script type="text/javascript" src="gollum.placeholder.js"></script>
  <script type="text/javascript" src="gollum.editor.js"></script>

  

  <title>` ~ fn ~ `</title>
</head>
<body>

<div id="wiki-wrapper" class="edit">
<div id="head">
  <h1>` ~ action ~ `<strong>` ~ fn ~ `</strong></h1>
</div>
  <div id="wiki-content"><div id="gollum-editor" data-escaped-name="add-name-here" class="edit ">
<form name="gollum-editor" action="/save?file=` ~ fn ~ `" method="post">
  <fieldset id="gollum-editor-fields">
  <input type="hidden" name="file" value="` ~ fn ~ `">
  <input type="hidden" name="path" id="gollum-editor-page-path" value="/">
  <div id="gollum-editor-function-bar">
    <div id="gollum-editor-function-buttons">
    <a href="#" id="function-bold" class="function-button">
      <span>Bold</span></a>
    <a href="#" id="function-italic" class="function-button">
      <span>Italic</span></a>
    <a href="#" id="function-code" class="function-button">
      <span>Code</span></a>
    <span class="function-divider">&nbsp;</span>
    <a href="#" id="function-ul" class="function-button">
      <span>Unordered List</span></a>
    <a href="#" id="function-ol" class="function-button">
      <span>Ordered List</span></a>
    <a href="#" id="function-blockquote" class="function-button">
      <span>Blockquote</span></a>

    <a href="#" id="function-hr" class="function-button">
      <span>Horizontal Rule</span></a>
    <span class="function-divider">&nbsp;</span>
    <a href="#" id="function-h1" class="function-button">
      <span>h1</span></a>
    <a href="#" id="function-h2" class="function-button">
      <span>h2</span></a>
    <a href="#" id="function-h3" class="function-button">
      <span>h3</span></a>
    <span class="function-divider">&nbsp;</span>
    <a href="#" id="function-link" class="function-button">
      <span>Link</span></a>
    <a href="#" id="function-image" class="function-button">
      <span>Image</span></a>
    <span class="function-divider">&nbsp;</span>
    <a href="#" id="function-help" class="function-button">
      <span>Help</span></a>
    </div>

    <div id="gollum-editor-format-selector">
      <label for="format">Edit Mode</label>
      <select id="wiki_format" name="format">
        <option value="asciidoc">
          AsciiDoc
        </option>
        <option value="creole">
          Creole
        </option>
        <option value="markdown">
          Markdown
        </option>
        <option value="mediawiki">
          MediaWiki
        </option>
        <option value="org">
          Org-mode
        </option>
        <option value="txt">
          Plain Text
        </option>
        <option value="pod">
          Pod
        </option>
        <option value="rdoc">
          RDoc
        </option>
        <option value="rest">
          reStructuredText
        </option>
        <option value="textile">
          Textile
        </option>
     </select>
    </div>
  </div>
  <div id="gollum-editor-help" class="jaws">
    <ul id="gollum-editor-help-parent">
      <li><a href="javascript:void(0);" class="selected">Help 1</a></li>
      <li><a href="javascript:void(0);">Help 1</a></li>
      <li><a href="javascript:void(0);">Help 1</a></li>
    </ul>
    <ul id="gollum-editor-help-list">
      <li><a href="javascript:void(0);">Help 2</a></li>
      <li><a href="javascript:void(0);">Help 3</a></li>
      <li><a href="javascript:void(0);">Help 4</a></li>
      <li><a href="javascript:void(0);">Help 5</a></li>
      <li><a href="javascript:void(0);">Help 6</a></li>
      <li><a href="javascript:void(0);">Help 7</a></li>
      <li><a href="javascript:void(0);">Help 8</a></li>
    </ul>
    <div id="gollum-editor-help-wrapper">
      <div id="gollum-editor-help-content">
      <p>
      </p>
      </div>
    </div>
  </div>
    <textarea id="gollum-editor-body"
     data-markup-lang="markdown" name="content" class="mousetrap">` ~ txt ~ `</textarea>
    <div>
      <i class="fa fa-spinner fa-spin"></i>
      Uploading file ...
    </div>




    <div id="gollum-editor-edit-summary" class="singleline">
      <label for="message" class="jaws">Edit message:</label>
      <input type="text" name="message" id="gollum-editor-message-field" value="Updated ` ~ fn ~ `">
    </div>

    <span class="jaws"><br></span>
    <input type="submit" id="gollum-editor-submit" value="Save and View" title="Save current changes">
    <a href="/view?file=` ~ fn ~ `" id="gollum-editor-preview" class="minibutton" title="Preview this Page">View (New Window)</a>
  </fieldset>
</form>
</div>
</div>
</div>


</body>
</html>
`;
}

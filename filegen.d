import std.file, std.path;

void main() {
	string result;
	foreach(f; 
	["asciidoc.js",
	 "creole.js",
	 "custom.css",
	 "dialog.css",
	 "editor.css",
	 "gollum.css",
	 "gollum.dialog.js",
	 "gollum.editor.js",
	 "gollum.js",
	 "gollum.placeholder.js",
	 "jquery-1.7.2.min.js",
	 "markdown.js",
	 "mousetrap.min.js",
	 "org.js",
	 "pod.js",
	 "print.css",
	 "rdoc.js",
	 "template.css",
	 "textile.js"]) {
		result ~= readText("src/" ~ f) ~ "\n##file##\n";
	}
	std.file.write("dependencies.txt", result);
}

# rtm-parser
ANTLR4 RTM Parser

After cloning repo, go to grammars/RtmParser.g4 file and save. This should put the ANTLR generated files into parsers/ folder

There are two debug configurations:

'.NET Core Launch (console)' will run Program.cs passing examples/input.txt as an argument.

'Debug ANTLR4 grammar' will run the ANTLR interpreter built into the vscode extension. Also uses input.txt.
Set "visualParseTree" to 'true' in launch.json if you want to see visual representation.
More info on the extension: https://github.com/mike-lischke/vscode-antlr4

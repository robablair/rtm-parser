using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using Antlr4.Runtime;

namespace TestAntlr
{
    class Program
    {
        static void Main(string[] args)
        {
            if (args.Length < 1)
                return;
            IEnumerable<string> files = null;
            if (System.IO.Directory.Exists(args[0]))
                files = System.IO.Directory.GetFiles(args[0]);
            else
                files = args;
            foreach (var file in files)
            {
                var inputStream = new AntlrInputStream(new StreamReader(file));
                var lexer = new RtmLexer(inputStream);
                // printTokens(lexer);
                var tokenStream = new CommonTokenStream(lexer);
                var parser = new RtmParser(tokenStream);
                parser.Interpreter.PredictionMode = Antlr4.Runtime.Atn.PredictionMode.SLL;
                // parser.BuildParseTree = false;
                // lexer.RemoveErrorListeners();
                // parser.RemoveErrorListeners();
                // parser.Profile = true;
                try
                {
                    var watch = new Stopwatch();
                    watch.Start();
                    var cst = parser.start();
                    watch.Stop();
                    if (parser.NumberOfSyntaxErrors > 0)
                    {
                        Console.WriteLine($"{new FileInfo(file).Name}: {parser.NumberOfSyntaxErrors} errors.");
                        Console.WriteLine($"{watch.Elapsed}");
                    }
                    Console.WriteLine($"{watch.Elapsed}");
                    // Program.profileParser(parser);
                    // Console.WriteLine("= {0}", cst.ToStringTree());
                }
                catch (Exception ex)
                {
                    Console.WriteLine(ex.Message);
                }
            }

            Console.WriteLine();
        }

        static void printTokens(RtmLexer lexer)
        {
            var tokenNames = lexer.RuleNames.Where(x => lexer.TokenTypeMap.ContainsKey(x)).Select(x => new { index = lexer.TokenTypeMap[x], name = x }).ToList();
            var sb = new StringBuilder();
            IToken token = null;
            while ((token = lexer.NextToken()).Type != RtmLexer.Eof)
            {
                var tokenName = tokenNames.First(x => x.index == token.Type).name;
                sb.Append($"[{token.Line},{token.Column}] {tokenName}: {ReplaceNewlines(token.Text)}");
                if (token.Channel != 0)
                    sb.Append($" (CHANNEL: {token.Channel})");
                sb.AppendLine();
            }
            Console.WriteLine(sb.ToString());
            lexer.Reset();
        }

        static string ReplaceNewlines(string text)
        {
            return text.Replace("\r\n", "\\r\\n").Replace("\r", "\\r").Replace("\n", "\\n");
        }

        static void profileParser(RtmParser parser)
        {
            Console.WriteLine($"{"rule",19}{"timeInPrediction",18}{"invocations",13}{"SLL_TotalLook",15}{"SLL_MaxLook",13}{"ambiguities",13}{"errors",8}");
            foreach (var decisionInfo in parser.ParseInfo.getDecisionInfo())
            {
                var decisionState = parser.Atn.GetDecisionState(decisionInfo.decision);
                var rule = parser.RuleNames[decisionState.ruleIndex];
                if (decisionInfo.timeInPrediction > 0)
                {
                    Console.WriteLine($"{rule,19}{decisionInfo.timeInPrediction,18}{decisionInfo.invocations,13}{decisionInfo.SLL_TotalLook,15}{decisionInfo.SLL_MaxLook,13}{decisionInfo.ambiguities.Count,13}{decisionInfo.errors.Count,8}");
                }
            }
        }
    }
}

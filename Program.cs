using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using Antlr4.Runtime;
using Antlr4.Runtime.Misc;

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
            var watch = new Stopwatch();
            var totalWatch = new Stopwatch();
            for (int i = 0; i < 2; i++)
            {
                totalWatch.Restart();
                var failedToParse = new Collection<FileInfo>();
                var sllParseTimes = new List<long>();
                var llParseTimes = new List<long>();
                foreach (var file in files)
                {
                    var fileInfo = new FileInfo(file);
                    var inputStream = new AntlrInputStream(new StreamReader(file));
                    var lexer = new RtmLexer(inputStream);
                    // printTokens(lexer);
                    var parser = new RtmParser(new CommonTokenStream(lexer));
                    parser.Interpreter.PredictionMode = Antlr4.Runtime.Atn.PredictionMode.SLL;
                    parser.RemoveErrorListeners();
                    parser.ErrorHandler = new BailErrorStrategy();
                    parser.Profile = true;
                    try
                    {
                        watch.Restart();
                        var cst = parser.start();
                        watch.Stop();
                        sllParseTimes.Add(watch.ElapsedMilliseconds);
                        if (parser.NumberOfSyntaxErrors > 0)
                        {
                            failedToParse.Add(fileInfo);
                            Console.WriteLine($"{fileInfo.Name}: {parser.NumberOfSyntaxErrors} errors.");
                            Console.WriteLine($"{watch.Elapsed}");
                        }
                    }
                    catch (ParseCanceledException)
                    {
                        Console.WriteLine($"{fileInfo.Name} failed to parse in SLL mode.");
                        lexer.Reset();
                        // parser.Reset();
                        parser = new RtmParser(new CommonTokenStream(lexer));
                        parser.AddErrorListener(ConsoleErrorListener<IToken>.Instance);
                        parser.ErrorHandler = new DefaultErrorStrategy();
                        parser.Interpreter.PredictionMode = Antlr4.Runtime.Atn.PredictionMode.LL;
                        watch.Restart();
                        var cst = parser.start();
                        watch.Stop();
                        llParseTimes.Add(watch.ElapsedMilliseconds);
                        if (parser.NumberOfSyntaxErrors > 0)
                        {
                            failedToParse.Add(fileInfo);
                            Console.WriteLine($"{fileInfo.Name}: {parser.NumberOfSyntaxErrors} errors.");
                            Console.WriteLine($"{watch.Elapsed}");
                        }
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine(ex.Message);
                    }
                    Program.profileParser(parser);
                }
                totalWatch.Stop();
                Console.WriteLine($"sllParseTimes: {sllParseTimes.Sum()}");
                Console.WriteLine($"llParseTimes: {llParseTimes.Sum()}");
                Console.WriteLine($"Total time: {totalWatch.ElapsedMilliseconds}");
                if (failedToParse.Count > 0)
                {
                    Console.WriteLine("Failed to parse:");
                    Console.Write(string.Join("\n", failedToParse.Select(x => x.Name)));
                }
                else
                {
                    Console.WriteLine("All parsed without error");
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

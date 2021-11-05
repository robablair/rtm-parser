using System;
using System.IO;
using Antlr4.Runtime;

namespace TestAntlr
{
    class Program
    {
        static void Main(string[] args)
        {
            var inputStream = new AntlrInputStream(new StreamReader(args[0]));
            var lexer = new RtmLexer(inputStream);
            var tokenStream = new CommonTokenStream(lexer);
            var parser = new RtmParser(tokenStream);

            try
            {
                var cst = parser.start();

                Console.WriteLine("= {0}", cst.ToStringTree());
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
            }

            Console.WriteLine();
        }
    }
}

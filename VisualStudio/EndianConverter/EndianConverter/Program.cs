using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Threading.Tasks;

namespace EndianConverter
{
    class Program
    {
        static void Main(string[] args)
        {

            byte readByteH, readByteL;
            UInt16 writeWord;

            //input file path from args
            if (File.Exists(args[0]))
            {
                string fileName = Path.GetFileNameWithoutExtension(args[0]);

                Console.WriteLine("Converting endianness in " + fileName);
                using (BinaryReader b = new BinaryReader(File.Open(args[0], FileMode.Open)))
                {
                    long length = b.BaseStream.Length;
                    long pos = 0;
                    using (BinaryWriter wl = new BinaryWriter(File.Open( (fileName + "[bE-low].bin"), FileMode.Create)))
                    {
                        while ( (pos < length) && (pos < 1048576 ))
                        {
                            //read 2 bytes from file
                            readByteH = b.ReadByte();
                            readByteL = b.ReadByte();

                            writeWord = (UInt16)(readByteL);
                            writeWord |= (UInt16)(readByteH << 8);

                            wl.Write(writeWord);

                            pos += 2;
                        }
                        wl.Close();
                    }
                    if (pos >= 1048576)
                    {
                        //do second half of 8Mbit ROM if applicable
                        using (BinaryWriter wh = new BinaryWriter(File.Open((fileName + "[bE-hi].bin"), FileMode.Create)))
                        {
                            while (pos < length)
                            {
                                //read 2 bytes from file
                                readByteH = b.ReadByte();
                                readByteL = b.ReadByte();

                                writeWord = (UInt16)(readByteL);
                                writeWord |= (UInt16)(readByteH << 8);

                                wh.Write(writeWord);

                                pos += 2;
                            }
                            wh.Close();
                        }
                    }
                }

                Console.WriteLine("Done!");
            }
            Console.WriteLine("Press enter to exit...");
            Console.ReadLine();
        }
    }
}

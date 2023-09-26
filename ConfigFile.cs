using System;
using System.Text.RegularExpressions;

/*
 * Configuration File Reader
 * 
 * Configuration file structure (# denotes comments):
 * 
 *      # FIELD     VALUE
 *      PARAM1      Parameter Value #1
 *      PARAM2      Parameter Value #2
 *      ARRAY1      one,two,three,foud
 * 
 * Usage:
 * 
 *      ConfigFile conf = new ConfigFile("<file-path>");
 *      string param1 = conf.getStringProperty("PARAM1");
 *      string[] ar1 = conf.getArrayProperty("ARRAY1");
 */

public class ConfigFile
{
    private Dictionary<string, string> config;
    private List<string> keys;

    public ConfigFile(string fileName)
    {
        this.config = new Dictionary<string, string>();
        this.keys = new List<string>();

        string[] settings = System.IO.File.ReadAllLines(fileName);

        foreach (var thisLine in settings)
        {
            if (Regex.Match(thisLine, @"^#").Success ||
                Regex.Match(thisLine, @"^[ \t]*$").Success)
            {
                continue;
            }
            else
            {
                var key = Regex.Replace(thisLine, @"^([^ \t]+)[ \t]+.*$", @"$1");
                var value = Regex.Replace(thisLine, @"^[^ \t]+[ \t]+(.*)$", @"$1");

                this.config[key] = value;
                this.keys.Add(key);
            }
        }
    }

    public string getStringProperty(string paramKey)
    {
        return (this.keys.IndexOf(paramKey) > -1) ? this.config[paramKey] : "";
    }

    public string[] getArrayProperty(string paramKey)
    {
        return (this.keys.IndexOf(paramKey) > -1) ? this.config[paramKey].Split(",") : new string[] { };
    }

}
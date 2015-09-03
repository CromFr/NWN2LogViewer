module AuroraServerNWScript;

import std.file;
import std.regex;
import std.string;
import std.conv;
import std.algorithm;

import logparser;
class BenchLog : LogParser{

	private string file;
	this(string _file){
		file = _file;
		assert(file.exists, file~" doesn't exists");
		assert(file.isFile, file~" is not a file");

		columns = Json(q"[
			{ 'name': 'Name',           'code': 'name'         },
			{ 'name': 'Type',           'code': 'type'         },
			{ 'name': 'Avg run time',   'code': 'avgRunTime'   },
			{ 'name': 'Calls',          'code': 'calls'        },
			{ 'name': 'Total run time', 'code': 'totalRunTime' }
		]");
	}

	override Json getData() {
		enum rgxScript = ctRegex!r"\[.+?\] (.+?) - \((.+?)\) \(([0-9]+) calls, [0-9]+ script situations, [0-9]+ bytes VA space usage, ([0-9]+)ms runtime\)\.";

		struct Entry{
			string name;
			string type;
			int calls;
			int runtime;

			float avgRunTime;
		}

		Entry[string] data;

		file.readText
		    .matchAll(rgxScript)
		    .each!((m){
		    	auto calls = m[3].to!uint;
		    	auto rtime = m[4].to!uint;
				data[m[1]] = Entry(m[1],m[2],calls,rtime,rtime/(calls*1.0));
			});

		return data.values.serializeToJson;
	}


}



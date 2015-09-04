module AuroraServerNWScript;

import std.file;
import std.regex;
import std.string;
import std.conv;
import std.algorithm;

import logparser;

class BenchLog : DataProvider{

	private string file;
	this(Json config){
		file = config.AuroraServerNWScript.BenchLog.file.to!string;
		assert(file.exists, file~" doesn't exists");
		assert(file.isFile, file~" is not a file");

		columns = [
			Column("Name","name"),
			Column("Type","type"),
			Column("Avg run time","avgRunTime"),
			Column("Calls","calls"),
			Column("Total run time","totalRunTime"),
		];
	}

	override Json getData(Json settings=null) {
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


		return Json([
			"columns": columns.serializeToJson,
			"data": data.values.serializeToJson
		]);
	}


}



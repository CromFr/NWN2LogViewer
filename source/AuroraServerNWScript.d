module AuroraServerNWScript;

import std.file;
import std.regex;
import std.string;
import std.conv;
import std.algorithm;

import logparser;


//Config:
//	file: Path to AuroraServerNWScript log file
//

class Benchmark : DataProvider{

	private string file;
	this(Json config){
		import std.exception;
		assertNotThrown(config.file.to!string, __MODULE__~" need a file path");
		file = config.file.to!string;

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
		enum rgxScript = ctRegex!r"\[(.+?)\] (.+?) - \((.+?)\) \(([0-9]+) calls, [0-9]+ script situations, [0-9]+ bytes VA space usage, ([0-9]+)ms runtime\)\.";

		struct Entry{
			string name;
			string type;
			int calls;
			int totalRunTime;

			float avgRunTime;
		}

		Entry[string] data;

		file.readText
			.matchAll(rgxScript)
			.each!((m){
				auto calls = m[4].to!uint;
				auto rtime = m[5].to!uint;
				data[m[2]] = Entry(m[2],m[3],calls,rtime,rtime/(calls*1.0));
			});


		return Json([
			"columns": columns.serializeToJson,
			"data": data.values.serializeToJson
		]);
	}
}


class Errors : DataProvider{

	private string file;
	this(Json config){
		import std.exception;
		assertNotThrown(config.file.to!string, __MODULE__~" need a file path");
		file = config.file.to!string;
		
		assert(file.exists, file~" doesn't exists");
		assert(file.isFile, file~" is not a file");

		columns = [
			Column("Date","date"),
			Column("Erreur","error"),
		];
	}

	override Json getData(Json settings=null) {
		enum rgxScript = ctRegex!r"\[(.+?)\] (.*?(Exception|Failed|ERROR).*?)";


		struct Entry{
			string date;
			string error;
		}

		Entry[] data;

		file.readText
			.matchAll(rgxScript)
			.each!((m){
				data ~= Entry(m[1],m[2]);
			});


		return Json([
			"columns": columns.serializeToJson,
			"data": data.serializeToJson
		]);
	}
}
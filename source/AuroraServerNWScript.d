module AuroraServerNWScript;

import std.file;
import std.regex;
import std.string;
import std.conv;
import std.algorithm;
import std.encoding;
import std.utf;

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
			Column("Name","name", ColumnType.TEXT),
			Column("Type","type", ColumnType.TEXT),
			Column("Avg run time (ms)","avgRunTime", ColumnType.FLOAT),
			Column("Calls","calls", ColumnType.INT),
			Column("Total run time (ms)","totalRunTime", ColumnType.FLOAT),
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


		string dataString;
		try{
			dataString = file.readText;
		}
		catch(UTFException e){
			transcode(cast(Windows1252String)(file.read), dataString);
		}
		dataString
			.matchAll(rgxScript)
			.each!((m){
				auto calls = m[4].to!uint;
				auto rtime = m[5].to!uint;
				data[m[2]] = Entry(m[2],m[3],calls,rtime,rtime/(calls*1.0));
			});

		return serializeDataToJson(data.values);
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
			Column("Date","date", ColumnType.DATE),
			Column("Error","error", ColumnType.TEXT),
			Column("Task","task", ColumnType.TEXT),
			Column("Script","script", ColumnType.TEXT),
		];
	}

	override Json getData(Json settings=null) {
		//NWScriptVM::AnalyzeScript( ot_userdefined ): Exception analyzing script: 'trivial infinite loop detected'.
		enum rgxScript = ctRegex!r"\[(.+?)\] (.+?::.+?)\(\s*([^\s]*)\s*\): (.*?(Exception|Failed|ERROR).*)";


		struct Entry{
			string date;
			string task;
			string script;
			string error;
		}

		Entry[] data;

		string dataString;
		try{
			dataString = file.readText;
		}
		catch(UTFException e){
			transcode(cast(Windows1252String)(file.read), dataString);
		}
		dataString
			.matchAll(rgxScript)
			.each!((m){
				data ~= Entry(m[1],m[2],m[3],m[4]);
			});


		return serializeDataToJson(data);
	}
}
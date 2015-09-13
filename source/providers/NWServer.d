module NWServer;

import std.file;
import std.regex;
import std.string;
import std.conv;
import std.algorithm;
import std.encoding;
import std.utf;
import std.datetime;
import std.exception;

import dataprovider;


///
enum timestamp = r"\[(.{3} .{3} \d{2} \d{2}:\d{2}:\d{2})\]";

///
DateTime shittyTimestampToDateTime(in string ts){
	string monthString;
	switch(ts[4..7]){
		case "Jan": monthString="01"; break;
		case "Feb": monthString="02"; break;
		case "Mar": monthString="03"; break;
		case "Apr": monthString="04"; break;
		case "May": monthString="05"; break;
		case "Jun": monthString="06"; break;
		case "Jul": monthString="07"; break;
		case "Aug": monthString="08"; break;
		case "Sep": monthString="09"; break;
		case "Oct": monthString="10"; break;
		case "Nov": monthString="11"; break;
		case "Dec": monthString="12"; break;
		default:    enforce(0, "Invalid month string: "~ts[4..7]);
	}
	return parseDateTime!"MM DD hh:mm:ss"(monthString~ts[7..$]);
}

///
class Lcda : DataProvider{

	private string file;
	///
	this(Json config){
		assertNotThrown(config.file.to!string, __MODULE__~" need a file path");
		file = config.file.to!string;

		assert(file.exists, file~" doesn't exists");
		assert(file.isFile, file~" is not a file");

		columns = [
			Column("Date","date", ColumnType.DATE),
			Column("Type","type", ColumnType.TEXT),
			Column("Message","message", ColumnType.TEXT),
		];
	}

	override Json getData(Json settings=null) {
		//KINDER|ITEMMAJ|TRANSFERT|CONNECTION|DISCONNECTION|PCDEATH

		struct Entry{
			string date;
			string type;
			string message;
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
			.matchAll(ctRegex!(timestamp~r"\s*\[([A-Z_]+)\]\s*(.*)"))
			.each!((m){
				data ~= Entry(m[1],m[2],m[3]);
			});

		return serializeDataToJson(data);
	}

}

///
class General : DataProvider{

	private string file;
	///
	this(Json config){
		assertNotThrown(config.file.to!string, __MODULE__~" need a file path");
		file = config.file.to!string;

		assert(file.exists, file~" doesn't exists");
		assert(file.isFile, file~" is not a file");

		columns = [
			Column("Date","date", ColumnType.DATE),
			Column("Exact date","exactDate", ColumnType.BOOL),
			Column("Message","message", ColumnType.TEXT),
		];
	}

	override Json getData(Json settings=null) {
		import std.algorithm : stripLeft;
		enum rgxBlackList = ctRegex!r"^(Created .+? of .+? on .+|.+? Died|\*\*DESIGN\*\*\*|\*+?)$";

		struct Entry{
			DateTime date;
			bool approxDate;
			string message;
		}

		Entry[] data;

		string dataString;
		try{
			dataString = file.readText;
		}
		catch(UTFException e){
			transcode(cast(Windows1252String)(file.read), dataString);
		}

		auto lines = dataString.splitLines;

		DateTime prevDate = DateTime(Clock.currTime.year,1,1);
		foreach(line ; lines){
			auto stripped = line.stripLeft('.');
			DateTime date;

			auto timestampMatch = stripped.matchFirst(ctRegex!("^"~timestamp));
			if(!timestampMatch.empty){
				date = shittyTimestampToDateTime(timestampMatch[1]);
				date.year = prevDate.year;

				//rm timestamp from message
				stripped = stripped[timestampMatch[1].length+3 .. $];
			}
			else{
				//10 sec per '.' char
				date = prevDate;
			}

			//year passing
			if(prevDate>date){
				date.year = date.year+1;
				foreach(ref entry ; data){
					entry.date.year = entry.date.year-1;
				}
			}

			if(stripped.length>0 && stripped.matchFirst(rgxBlackList).empty)
				data ~= Entry(date, !timestampMatch.empty, stripped);
			prevDate = date;
		}

		return serializeDataToJson(data);
	}

}
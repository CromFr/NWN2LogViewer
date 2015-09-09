module dataprovider;

import vibe.http.router;
import vibe.web.rest;

public import vibe.data.json;
public import std.datetime : DateTime;

interface DataProviderIface {
	Json getData(Json settings=null);
}

/// Must implement this(Json config) in child class
/// The passed config is the config.cfg file from the /providers/YourModule
abstract class DataProvider : DataProviderIface{

	///
	void route(URLRouter router, in string pathPrefix){
		router.registerRestInterface(this, pathPrefix);
	}

	enum ColumnType{
		TEXT="text", INT="int", FLOAT="float", DATE="date", BOOL="bool"
	}

	///
	struct Column{
		string name;
		string code;
		ColumnType type;
	}
	protected Column[] columns;

	abstract Json getData(Json settings=null);


	protected Json serializeDataToJson(T)(T[] data) if(is(T==struct)) {
		assert(columns !is null && columns.length>0, "You must setup columns");
		assert(columns.length==__traits(allMembers, T).length, "columns must have as many columns as attributes in "~T.stringof);

		auto jsonData = Json.emptyArray;
		foreach(entry ; data){
			auto jsonEntry = Json.emptyArray;
			foreach(member ; __traits(allMembers, T)){
				static if(mixin("is("~member~":DateTime)"))
					jsonEntry.appendArrayElement(mixin("entry."~member).toISOExtString.serializeToJson());
				else
					jsonEntry.appendArrayElement(mixin("entry."~member).serializeToJson());
			}
			jsonData.appendArrayElement(jsonEntry);
		}

		return Json([
			"columns": columns.serializeToJson,
			"data": jsonData
		]);
	}

}


/// ex format: YYYY-MM-DD hh:mm:ss
DateTime parseDateTime(string format)(in string data){
	import std.conv : to;
	assert(format.length == data.length);

	string year,month,day,hour,minute,second;
	foreach(i ; 0..format.length){
		switch(format[i]){
			case 'Y': year~=data[i];   break;
			case 'M': month~=data[i];  break;
			case 'D': day~=data[i];    break;
			case 'h': hour~=data[i];   break;
			case 'm': minute~=data[i]; break;
			case 's': second~=data[i]; break;
			default:
		}
	}

	return DateTime(
		year is null?   0 : year.to!int,
		month is null?  1 : month.to!int,
		day is null?    1 : day.to!int,
		hour is null?   0 : hour.to!int,
		minute is null? 0 : minute.to!int,
		second is null? 0 : second.to!int
		);
}
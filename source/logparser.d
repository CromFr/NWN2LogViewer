module logparser;

import vibe.http.router;
import vibe.web.rest;

public import vibe.data.json;

interface DataProviderIface {
	Json getData(Json settings=null);
}


abstract class DataProvider : DataProviderIface{
	//Must implement this(Json config) in child class
	//  The passed config is the config.cfg file from the /providers/YourModule


	void route(URLRouter router, in string pathPrefix){
		router.registerRestInterface(this, pathPrefix);
	}

	enum ColumnType{
		TEXT="text", INT="int", FLOAT="float", DATE="date"
	}
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
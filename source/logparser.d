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
}
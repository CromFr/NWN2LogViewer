module logparser;

import vibe.http.router;
import vibe.web.rest;

public import vibe.data.json;

interface DataProviderIface {
	Json getData(Json settings=null);
}


class DataProvider : DataProviderIface{

	void route(URLRouter router, in string pathPrefix){
		router.registerRestInterface(this, pathPrefix);
	}

	struct Column{
		string name;
		string code;
	}
	protected Column[] columns;

	abstract Json getData(Json settings=null);
}
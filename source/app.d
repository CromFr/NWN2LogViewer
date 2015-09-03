import vibe.d;

shared static this()
{
	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];
	listenHTTP(settings, &hello);
	router.registerRestInterface(new MyAPIImplementation);

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}




interface LogIface {

	Json getData(string moduleName, string className);
	Json getColumns(string moduleName, string className);
}

class LogAPI : LogIface {
	immutable classList;

	this(){
		classList = [
			"AuroraServerNWScript.BenchLog":
				new AuroraServerNWScript.BenchLog(`C:\nwnx4\AuroraServerNWScript.log`),
		];
	}

	Json getData(string moduleName, string className){
		string thisClass = moduleName~"."~className;

		return classList[thisClass].getData();
	}
	Json getColumns(string moduleName, string className){
		string thisClass = moduleName~"."~className;

		return classList[thisClass].getColumns();
	}
}




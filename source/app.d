import vibe.d;
import logparser;

shared static this()
{
	auto router = new URLRouter;

	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];

	router.get("/", serveStaticFile("index.html"));
	router.registerRestInterface(new LogAPI);

	listenHTTP(settings, router);

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
}



interface LogIface {

	Json getData(string moduleName, string className);
	Json getColumns(string moduleName, string className);
}

class LogAPI : LogIface {
	LogParser[string] classList;

	this(){
		import AuroraServerNWScript;
		classList = [
			"AuroraServerNWScript.BenchLog":
				new AuroraServerNWScript.BenchLog(`C:\Program Files (x86)\Neverwinter Nights 2\nwnx4\AuroraServerNWScript.log`),
		];
	}
	string getTest(){
		return "hello";
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




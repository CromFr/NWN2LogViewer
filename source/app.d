import std.stdio;
import logparser;

import vibe.d;

//All modules to import, where DataProviders are written
enum ProviderModuleList {
	AuroraServerNWScript
}


shared static this()
{
	auto router = new URLRouter;

	auto settings = new HTTPServerSettings;
	settings.port = 8080;
	settings.bindAddresses = ["::1", "127.0.0.1"];

	router.get("*", serveStaticFiles("./public/"));

	auto config = [
		"AuroraServerNWScript":[
			"BenchLog":[
				"file": "AuroraServerNWScript.log"
			]
		]
	].serializeToJson;

	//Providers are available at: /ModuleName/ClassName
	DataProvider[string] classList = mixin("["~ListAllProviders()~"]");

	foreach(path, c ; classList){
		c.route(router, path);
	}

	listenHTTP(settings, router);

	writeln("http://127.0.0.1:8080/");
}





//Import all modules from ProviderModuleList
mixin({
	import std.traits;
	import std.conv;
	string ret;
	foreach(mod ; EnumMembers!ProviderModuleList){
		ret~="import "~mod.to!string~";";
	}
	return ret;
}());

string ListAllProviders(){
	import std.traits;
	import std.conv;

	string ret;

	foreach(mod ; EnumMembers!ProviderModuleList){
		foreach(member ; __traits(allMembers, mixin(mod.to!string))){

			immutable string memberFullName = mod.to!string~"."~member.to!string;

			static if(
				mixin("is("~memberFullName~" == class)")
				&& isImplicitlyConvertible!(mixin(memberFullName), DataProvider)){
		
				pragma(msg, "- Registered: "~memberFullName);

				ret ~= "\"/"~(mod.to!string)~"/"~(member.to!string)~"\": new "~memberFullName~"(config),";

			}
		}
	}
	return ret;
}
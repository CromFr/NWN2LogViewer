import std.stdio;
import std.file : readText;
import std.regex;
import std.algorithm;
import std.traits;
import logparser;

import vibe.d;

//All modules to import, where DataProviders are written
enum ProviderModuleList {
	AuroraServerNWScript
}


int main(string[] args)
{

	if (!finalizeCommandLineOptions())
		return 0;

	auto config = "config.json"
		.readText
		.replaceAll(ctRegex!r"//.*", " ")
		.parseJsonString;


	auto settings = new HTTPServerSettings;

	//Read settings from config.json
	foreach(key, value ; config["server"].get!(Json[string])){

		foreach(member ; __traits(allMembers, HTTPServerSettings)){
			static if(!isCallable!(mixin("HTTPServerSettings."~member)) && member!="Monitor"){

				if(key == member){
					static if(isSomeString!(mixin("typeof(HTTPServerSettings."~member~")"))
						   || __traits(isArithmetic, mixin("HTTPServerSettings."~member))
						){
						//pragma(msg, "=====X "~member);
						try{
							auto buff = mixin("value.to!(OriginalType!(typeof(HTTPServerSettings."~member~")))");
							mixin("settings."~member~" = cast(typeof(HTTPServerSettings."~member~"))buff;");
							writeln("-- server."~member~"=",mixin("settings."~member));
						}
						catch(JSONException){}
					}
					else static if(mixin("is(typeof(HTTPServerSettings."~member~") == Duration)")){
						//pragma(msg, "=====D "~member);
						try{
							mixin("settings."~member~" = dur!\"seconds\"(value.to!uint);");
							writeln("-- server."~member~"=",mixin("settings."~member));
						}
						catch(JSONException){}
					}
					else static if(mixin("is(typeof(HTTPServerSettings."~member~") == string[])") ){
						//pragma(msg, "====[] "~member);
						try{
							mixin("settings."~member~" = 
								(value[])
								.map!((a){return a.to!string;})
								.array;");
							writeln("-- server."~member~"=",mixin("settings."~member));
						}
						catch(JSONException){}
					}
				}
			}
		}
	}

	//Providers are available at: /ModuleName/ClassName
	DataProvider[string] classList = mixin("["~ListAllProviders()~"]");

	auto router = new URLRouter;
	router.get("*", serveStaticFiles("./public/"));
	router.get("/providers", (HTTPServerRequest req, HTTPServerResponse res){

		Json list = Json.emptyObject;
		classList
			.keys
			.each!((a){
				immutable b = a[1..$].split("/");
				if(b[0] !in list)
					list[b[0]] = Json.emptyArray;
				list[b[0]].appendArrayElement(Json(b[1]));
			});

		res.writeJsonBody(list);
	});

	foreach(path, c ; classList){
		c.route(router, path);
	}

	listenHTTP(settings, router);

	lowerPrivileges();
	writeln("==> http://127.0.0.1:"~settings.port.to!string~"/");
	return runEventLoop();
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
	import std.conv;
	import std.file;

	string ret;

	foreach(mod ; EnumMembers!ProviderModuleList){
		foreach(member ; __traits(allMembers, mixin(mod.to!string))){

			immutable string memberFullName = mod.to!string~"."~member.to!string;

			static if(
				mixin("is("~memberFullName~" == class)")
				&& isImplicitlyConvertible!(mixin(memberFullName), DataProvider)){

				pragma(msg, "- Registered: "~memberFullName);
				ret ~= "\"/"~(mod.to!string)~"/"~(member.to!string)~"\": new "~memberFullName~"(config.providers."~mod.to!string~"),";

			}
		}
	}
	return ret;
}
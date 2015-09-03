module logparser;

public import vibe.data.json;

class LogParser{
	abstract Json getData();
	Json getColumns(){
		return columns;
	}
	
	protected Json columns;
}
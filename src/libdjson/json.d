/**
 * LibDJSONcontains functions and classes for reading, parsing, and writing JSON
 * documents.
 *
 * Copyright:	(c) 2009 William K. Moore, III (nyphbl8d (at) gmail (dot) com, opticron on freenode)
 * Authors:	William K. Moore, III
 * License:	Boost Software License - Version 1.0 - August 17th, 2003

 Permission is hereby granted, free of charge, to any person or organization
 obtaining a copy of the software and accompanying documentation covered by
 this license (the "Software") to use, reproduce, display, distribute,
 execute, and transmit the Software, and to prepare derivative works of the
 Software, and to permit third-parties to whom the Software is furnished to
 do so, all subject to the following:

 The copyright notices in the Software and this entire statement, including
 the above license grant, this restriction and the following disclaimer,
 must be included in all copies of the Software, in whole or in part, and
 all derivative works of the Software, unless such copies or derivative
 works are solely in the form of machine-executable object code generated by
 a source language processor.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
 SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
 FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
 ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.

 * Standards:	Attempts to conform to the subset of Javascript required to implement the JSON Specification
 */

/* My TODO list:
 *	implement some kind of XPath like search ability
 */
module libdjson.json;
version(Tango) {
	import tango.text.Util:isspace=isSpace,stripl=triml,strip=trim,stripr=trimr,find=locatePattern,split,replace=substitute;
	import tango.text.convert.Integer:tostring=toString,agToULong=toLong;
	import tango.text.convert.Float:tostring=toString,agToFloat=toFloat;
	import tango.text.Ascii:icmp=icompare,cmp=compare;
	import tango.io.Stdout:writef=Stdout;
	import tango.text.Regex;
	alias char[] string;
	string regrep(string input,string pattern,string delegate(string) translator) {
		string tmpdel(RegExpT!(char) m) {
			return translator(m.match(0));
		}
		auto rgxp = Regex(pattern,"g");
		return rgxp.replaceAll(input,&tmpdel);
	}
} else {
	version(D_Version2) {
		import std.conv:to;
		import std.string:strip,stripr,stripl=stripLeft,split,replace,find=indexOf,cmp,icmp;
		import std.ascii:isspace=isWhite;
		real agToFloat(string data) {
			return to!(real)(data);
		}
		ulong agToULong(string data) {
			return to!(ulong)(data);
		}
		string tostring(real data) {
			return to!(string)(data);
		}
	} else {
		import std.string:tostring=toString,strip,stripr,stripl,split,replace,find,cmp,icmp;
		import std.conv:agToULong=toUlong,agToFloat=toReal;
		import std.ctype:isspace;
	}
	import std.stdio:writef;
	import std.regexp:sub,RegExp;
	//import std.utf:toUTF8;
	string regrep(string input,string pattern,string delegate(string) translator) {
		string tmpdel(RegExp m) {
			return translator(m.match(0));
		}
		return sub(input,pattern,&tmpdel,"g");
	}
}

/**
 * Read an entire string into a JSON tree.
 * Example:
 * --------------------------------
 * auto root = new JSONObject();
 * auto arr = new JSONArray();
 * arr ~= new JSONString("da blue teeths!\"\\");
 * root["what is that on your ear?"] = arr;
 * root["my pants"] = new JSONString("are on fire");
 * root["i am this many"] = new JSONNumber(10.253);
 * string jstr = root.toString;
 * writef("Unit Test libDJSON JSON creation...\n");
 * writef("Generated JSON string: ");writef(jstr);writef("\n");
 * writef("Regenerated JSON string: ");writef(readJSON(jstr).toString);writef("\n");
 * --------------------------------
 * Returns: A JSONObject with no name that is the root of the document that was read.
 * Throws: JSONError on any parsing errors.
 */
JSONType readJSON(string src) {
	string pointcpy = src;
	JSONType root = null;
	try {
		src = src.stripl();
		root = parseHelper(src);
	} catch (JSONError e) {
		writef("Caught exception from input string:\n" ~ pointcpy ~ "\n");
		throw e;
	}
	return root;
}

/// An exception thrown on JSON parsing errors.
class JSONError : Exception {
	// Throws an exception with an error message.
	this(string msg) {
		super(msg);
	}
}

/// This is the interface implemented by all classes that represent JSON objects.
interface JSONType {
	string toString();
	string toPrettyString(string indent=null);
	/// The parse method of this interface should ALWAYS be destructive, removing things from the front of source as it parses.
	void parse(ref string source);
	/// Convenience function for casting to JSONObject.
	/// Returns: The casted reference or null on a failed cast.
	JSONObject toJSONObject();
	/// Convenience function for casting to JSONArray.
	/// Returns: The casted reference or null on a failed cast.
	JSONArray toJSONArray();
	/// Convenience function for casting to JSONString.
	/// Returns: The casted reference or null on a failed cast.
	JSONString toJSONString();
	/// Convenience function for casting to JSONBoolean.
	/// Returns: The casted reference or null on a failed cast.
	JSONBoolean toJSONBoolean();
	/// Convenience function for casting to JSONNumber.
	/// Returns: The casted reference or null on a failed cast.
	JSONNumber toJSONNumber();
	/// Convenience function for casting to JSONNull.
	/// Returns: The casted reference or null on a failed cast.
	JSONNull toJSONNull();
	/// Associative array index function for objects describing associative array-like attributes.
	/// Returns: The chosen index or a null reference if the index does not exist.
	JSONType opIndex(string key);
	/// Allow foreach over the object with string key and ref value.
	int opApply(int delegate(ref string,ref JSONType) dg);
	/// Array index function for objects describing array-like attributes.
	/// Returns: The chosen index or a null reference if the index does not exist.
	JSONType opIndex(int key);
	/// Allow foreach over the object with integer key and ref value.
	int opApply(int delegate(ref int,ref JSONType) dg);
	/// Convenience function for iteration that apply to both AA and array type operations with ref value
	int opApply(int delegate(ref JSONType) dg);
	/// Allow "in" operator to work as expected for object types without an explicit cast
	JSONType*opIn_r(string key);
}
// everything needs these for ease of use
const string convfuncs = 
"
/// Convenience function for casting to JSONObject
/// Returns: The casted object or null if the cast fails
JSONObject toJSONObject(){return cast(JSONObject)this;}
/// Convenience function for casting to JSONArray
/// Returns: The casted object or null if the cast fails
JSONArray toJSONArray(){return cast(JSONArray)this;}
/// Convenience function for casting to JSONString
/// Returns: The casted object or null if the cast fails
JSONString toJSONString(){return cast(JSONString)this;}
/// Convenience function for casting to JSONBoolean
/// Returns: The casted object or null if the cast fails
JSONBoolean toJSONBoolean(){return cast(JSONBoolean)this;}
/// Convenience function for casting to JSONNumber
/// Returns: The casted object or null if the cast fails
JSONNumber toJSONNumber(){return cast(JSONNumber)this;}
/// Convenience function for casting to JSONNull
/// Returns: The casted object or null if the cast fails
JSONNull toJSONNull(){return cast(JSONNull)this;}";
// only non-arrays need this
const string convfuncsA = 
"
/// Dummy function for types that don't implement integer indexing.  Throws an exception.
JSONType opIndex(int key) {throw new JSONError(typeof(this).stringof ~\" does not support integer indexing, check your JSON structure.\");}
/// Dummy function for types that don't implement integer indexing.  Throws an exception.
int opApply(int delegate(ref int,ref JSONType) dg) {throw new JSONError(typeof(this).stringof ~\" does not support numeric index foreach, check your JSON structure.\");}
";
// only non-AAs need this
const string convfuncsAA = 
"
/// Dummy function for types that don't implement string indexing.  Throws an exception.
JSONType opIndex(string key) {throw new JSONError(typeof(this).stringof ~\" does not support string indexing, check your JSON structure.\");}
/// Dummy function for types that don't implement string indexing.  Throws an exception.
int opApply(int delegate(ref string,ref JSONType) dg) {throw new JSONError(typeof(this).stringof ~\" does not support string index foreach, check your JSON structure.\");}
/// Dummy function for types that don't implement string indexing (opIn_r).  Throws an exception.
JSONType*opIn_r(string key) {throw new JSONError(typeof(this).stringof ~\" does not support opIn, check your JSON structure.\");}
";
// neither arrays nor AAs need this
const string convfuncsAAA = 
"
/// Dummy function for types that don't implement any type of indexing.  Throws an exception.
int opApply(int delegate(ref JSONType) dg) {throw new JSONError(typeof(this).stringof ~\" does not support foreach, check your JSON structure.\");}
";
/**
 * JSONObject represents a single JSON object node and has methods for 
 * adding children.  All methods that make changes modify this
 * JSONObject rather than making a copy, unless otherwise noted.  Many methods
 * return a self reference to allow cascaded calls.
 */
class JSONObject:JSONType {
	/// Nothing to see here except for the boring constructor, move along.
	this(){}
	protected JSONType[string] _children;
	/// Operator overload for setting keys in the AA.
	void opIndexAssign(JSONType type,string key) {
		_children[key] = type;
	}
	/// Operator overload for accessing values already in the AA.
	/// Returns: The child node if it exists, otherwise null.
	JSONType opIndex(string key) {
		return (key in _children)?_children[key]:null;
	}
	/// Allow the user to get the number of elements in this object
	/// Returns: The number of child nodes contained within this JSONObject
	int length() {return _children.length;}
	/// Operator overload for foreach iteration through the object with values only and allow modification of the reference
	int opApply(int delegate(ref JSONType) dg) {
		int res;
		foreach(ref child;_children) {
			res = dg(child);
			if (res) return res;
		}
		return 0;
	}
	/// Operator overload for foreach iteration through the object with key and value and allow modification of the reference
	int opApply(int delegate(ref string,ref JSONType) dg) {
		int res;
		foreach(key,ref child;_children) {
			res = dg(key,child);
			if (res) return res;
		}
		return 0;
	}

	/// A method to convert this JSONObject to a user-readable format.
	/// Returns: A JSON string representing this object and it's contents.
	override string toString() {
		string ret;
		ret ~= "{";
		foreach (key,val;_children) {
			ret ~= "\""~JSONEncode(key)~"\":"~val.toString~",";
		}
		// rip off the trailing comma, we don't need it
		if (_children.length) ret = ret[0..$-1];
		ret ~= "}";
		return ret;
	}

	/// A method to convert this JSONObject to a formatted, user-readable format.
	/// Returns: A JSON string representing this object and it's contents.
	string toPrettyString(string indent=null) {
		string ret;
		ret ~= "{\n";
		foreach (key,val;_children) {
			ret ~= indent~"	\""~JSONEncode(key)~"\":"~val.toPrettyString(indent~"	")~",\n";
		}
		// rip off the trailing comma, we don't need it
		if (_children.length) ret = ret[0..$-2]~"\n";
		ret ~= indent~"}";
		return ret;
	}

	/// This function parses a JSONObject out of a string
	void parse(ref string source) {
		// make sure the first byte is {
		if (source[0] != '{') throw new JSONError("Missing open brace '{' at start of JSONObject parse: "~source);
		// rip off the leading {
		source = stripl(source[1..$]);
		while (source[0] != '}') {
			if (source[0] != '"') throw new JSONError("Missing open quote for element key before: "~source);
			// use JSONString class to help us out here (read, I'm lazy :D)
			auto jstr = new JSONString();
			jstr.parse(source);
			source = stripl(source);
			if (source[0] != ':') throw new JSONError("Missing ':' after keystring in object before: "~source);
			source = stripl(source[1..$]);
			_children[jstr.get] = parseHelper(source);
			source = stripl(source);
			// handle end cases
			if (source[0] == '}') continue;
			if (source[0] != ',') throw new JSONError("Missing continuation via ',' or end of JSON object via '}' before "~source);
			// rip the , in preparation for the next loop
			source = stripl(source[1..$]);
			// make sure we don't have a ",}", since I'm assuming it's not allowed
			if (source[0] == '}') throw new JSONError("Empty array elements (',' followed by '}') are not allowed. Fill the space or remove the comma.\nThis error occurred before: "~source);
		}
		// rip off the } and be done with it
		source = stripl(source[1..$]);
	}
	/// Allow "in" operator to work as expected for object types without an explicit cast
	JSONType*opIn_r(string key) {
		return key in _children;
	}
	mixin(convfuncs);
	mixin(convfuncsA);
}

/// JSONArray represents a single JSON array, capable of being heterogenous
class JSONArray:JSONType {
	/// Nothing to see here, move along.
	this(){}
	protected JSONType[] _children;
	/// Operator overload to allow addition of children
	void opCatAssign(JSONType child) {
		_children ~= child;
	}
	/// Operator overload to allow access of children
	/// Returns: The child node if it exists, otherwise null.
	JSONType opIndex(int key) {
		return _children[key];
	}
	/// Allow the user to get the number of elements in this object
	/// Returns: The number of child nodes contained within this JSONObject
	int length() {return _children.length;}
	/// Operator overload for foreach iteration through the array with values only and allow modification of the reference
	int opApply(int delegate(ref JSONType) dg) {
		int res;
		foreach(ref child;_children) {
			res = dg(child);
			if (res) return res;
		}
		return 0;
	}
	/// Operator overload for foreach iteration through the array with key and value and allow modification of the reference
	int opApply(int delegate(ref int,ref JSONType) dg) {
		int res;
		int tmp;
		foreach(key,ref child;_children) {
			tmp = key;
			res = dg(tmp,child);
			if (res) return res;
		}
		return 0;
	}

	/// A method to convert this JSONArray to a user-readable format.
	/// Returns: A JSON string representing this object and it's contents.
	override string toString() {
		string ret;
		ret ~= "[";
		foreach (val;_children) {
			ret ~= val.toString~",";
		}
		// rip off the trailing comma, we don't need it
		if (_children.length) ret = ret[0..$-1];
		ret ~= "]";
		return ret;
	}

	/// A method to convert this JSONArray to a formatted, user-readable format.
	/// Returns: A JSON string representing this object and it's contents.
	string toPrettyString(string indent=null) {
		string ret;
		ret ~= "[\n";
		foreach (val;_children) {
			ret ~= indent~"	"~val.toPrettyString(indent~"	")~",\n";
		}
		// rip off the trailing comma, we don't need it
		if (_children.length) ret = ret[0..$-2]~"\n";
		ret ~= indent~"]";
		return ret;
	}

	/// This function parses a JSONArray out of a string
	void parse(ref string source) {
		if (source[0] != '[') throw new JSONError("Missing open brace '[' at start of JSONArray parse: "~source);
		// rip off the leading [
		source = stripl(source[1..$]);
		while (source[0] != ']') {
			_children ~= parseHelper(source);
			source = stripl(source);
			// handle end cases
			if (source[0] == ']') continue;
			if (source[0] != ',') throw new JSONError("Missing continuation via ',' or end of JSON array via ']' before "~source);
			// rip the , in preparation for the next loop
			source = stripl(source[1..$]);
			// take care of trailing null entries
			if (source[0] == ']') _children ~= new JSONNull();
		}
		// rip off the ] and be done with it
		source = stripl(source[1..$]);
	}
	mixin(convfuncs);
	mixin(convfuncsAA);
}

/// JSONString represents a JSON string.  Internal representation is escaped for faster parsing and JSON generation.
class JSONString:JSONType {
	/// The boring default constructor.
	this(){}
	/// The ever so slightly more interesting initializing constructor.
	this(string data) {set(data);}
	protected string _data;
	/// Allow the data to be set so the object can be reused.
	void set(string data) {_data = JSONEncode(data);}
	/// Allow the data to be retreived.
	string get() {return JSONDecode(_data);}

	/// A method to convert this JSONString to a user-readable format.
	/// Returns: A JSON string representing this object and it's contents.
	override string toString() {
		return "\""~_data~"\"";
	}

	/// A method to convert this JSONString to a formatted, user-readable format.
	/// Returns: A JSON string representing this object and it's contents.
	string toPrettyString(string indent=null) {
		return toString;
	}

	/// This function parses a JSONArray out of a string and eats characters as it goes, hence the ref string parameter.
	void parse(ref string source) {
		if (source[0] != '"') throw new JSONError("Missing open quote '\"' at start of JSONArray parse: "~source);
		// rip off the leading [
		source = source[1..$];
		// scan to find the closing quote
		int bscount = 0;
		int sliceloc = -1;
		for(int i = 0;i<source.length;i++) {
			switch(source[i]) {
			case '\\':
				bscount++;
				continue;
			case '"':
				// if the count is even, backslashes cancel and we have the end of the string, otherwise cascade
				if (bscount%2 == 0) {
					break;
				}
			default:
				bscount = 0;
				continue;
			}
			// we have reached the terminating case! huzzah!
			sliceloc = i;
			break;
		}
		// take care of failure to find the end of the string
		if (sliceloc == -1) throw new JSONError("Unable to find the end of the JSON string starting here: "~source);
		_data = source[0..sliceloc];
		// eat the " that is known to be there
		source = stripl(source[sliceloc+1..$]);
	}
	mixin(convfuncs);
	mixin(convfuncsA);
	mixin(convfuncsAA);
	mixin(convfuncsAAA);
}

/// JSONBoolean represents a JSON boolean value.
class JSONBoolean:JSONType {
	/// The boring constructor, again.
	this(){}
	/// Only a bit of input for this constructor.
	this(bool data) {_data = data;}
	/// Allow setting of the hidden bit.
	void set(bool data) {_data = data;}
	/// Allow the bit to be retreived.
	bool get() {return _data;}
	protected bool _data;

	/// A method to convert this JSONBoolean to a user-readable format.
	/// Returns: A JSON string representing this object and it's contents.
	override string toString() {
		if (_data) return "true";
		return "false";
	}

	/// A method to convert this JSONBoolean to a formatted, user-readable format.
	/// Returns: A JSON string representing this object and it's contents.
	string toPrettyString(string indent=null) {
		return toString;
	}

	/// This function parses a JSONBoolean out of a string and eats characters as it goes, hence the ref string parameter.
	void parse(ref string source) {
		if (source[0..4] == "true") {
			source = stripl(source[4..$]);
			set(true);
		} else if (source[0..5] == "false") {
			source = stripl(source[5..$]);
			set(false);
		} else throw new JSONError("Could not parse JSON boolean variable from: "~source);
	}
	mixin(convfuncs);
	mixin(convfuncsA);
	mixin(convfuncsAA);
	mixin(convfuncsAAA);
}

/// JSONNull represents a JSON null value.
class JSONNull:JSONType {
	/// You're forced to use the boring constructor here.
	this(){}

	/// A method to convert this JSONNull to a user-readable format.
	/// Returns: "null". Always. Forever.
	override string toString() {
		return "null";
	}

	/// A method to convert this JSONNull to a formatted, user-readable format.
	/// Returns: "null". Always. Forever.
	string toPrettyString(string indent=null) {
		return toString;
	}

	/// This function parses a JSONNull out of a string.  Really, it just rips "null" off the beginning of the string and eats whitespace.
	void parse(ref string source) in { assert(source[0..4] == "null"); } body {
		source = stripl(source[4..$]);
	}
	mixin(convfuncs);
	mixin(convfuncsA);
	mixin(convfuncsAA);
	mixin(convfuncsAAA);
}

/// JSONNumber represents any JSON numeric value.
class JSONNumber:JSONType {
	/// Another boring constructor...
	this(){}
	/// ...and its slightly less boring sibling.
	this(real data) {_data = tostring(data);}
	this(long data) {_data = tostring(data);}
	this(int data) {_data = tostring(cast(long)data);}
	/// Allow setting of the hidden number.
	void set(real data) {_data = tostring(data);}
	void set(long data) {_data = tostring(data);}
	void set(int data) {_data = tostring(cast(long)data);}
	/// Allow the number to be retreived.
	real get() {return agToFloat(_data);}
	long getLong() {return agToULong(_data);}
	real getReal() {return agToULong(_data);}
	protected string _data;

	/// A method to convert this JSONNumber to a user-readable format.
	/// Returns: A JSON string representing this number.
	override string toString() {
		return _data;
	}

	/// A method to convert this JSONNumber to a formatted, user-readable format.
	/// Returns: A JSON string representing this number.
	string toPrettyString(string indent=null) {
		return toString;
	}

	/// This function parses a JSONNumber out of a string and eats characters as it goes, hence the ref string parameter.
	void parse(ref string source) {
		// this parser sucks...
		int i = 0;
		// check for leading minus sign
		if (source[i] == '-') i++;
		// sift through whole numerics
		if (source[i] == '0') {
			i++;
		} else if (source[i] <= '9' && source[i] >= '1') {
			while (source[i] >= '0' && source[i] <= '9') i++;
		} else throw new JSONError("A numeric parse error occurred while parsing the numeric beginning at: "~source);
		// if the next char is not a '.', we know we're done with fractional parts 
		if (source[i] == '.') {
			i++;
			while (source[i] >= '0' && source[i] <= '9') i++;
		}
		// if the next char is e or E, we're poking at an exponential
		if (source[i] == 'e' || source[i] == 'E') {
			i++;
			if (source[i] == '-' || source[i] == '+') i++;
			while (source[i] >= '0' && source[i] <= '9') i++;
		}
		_data = source[0..i];
		source = stripl(source[i..$]);
	}
	mixin(convfuncs);
	mixin(convfuncsA);
	mixin(convfuncsAA);
	mixin(convfuncsAAA);
}

private JSONType parseHelper(ref string source) {
	JSONType ret;
	switch(source[0]) {
	case '{':
		ret = new JSONObject();
		break;
	case '[':
		ret = new JSONArray();
		break;
	case '"':
		ret = new JSONString();
		break;
	case '-','0','1','2','3','4','5','6','7','8','9':
		ret = new JSONNumber();
		break;
	default:
		if (source.length >= 4 && source[0..4] == "null") ret = new JSONNull();
		else if ((source.length >= 4 && source[0..4] == "true") || (source.length >= 5 && source[0..5] == "false")) ret = new JSONBoolean();
		else if (source.length && source[0] == ',') return new JSONNull(); // no parse here
		else throw new JSONError("Unable to determine type of next element beginning: "~source);
		break;
	}
	ret.parse(source);
	return ret;
}

/// Perform JSON escapes on a string
/// Returns: A JSON encoded string
string JSONEncode(string src) {
	string tempStr;
        tempStr = replace(src    , "\\", "\\\\");
        tempStr = replace(tempStr, "\"", "\\\"");
        return tempStr;
}

/// Unescape a JSON string
/// Returns: A decoded string.
string JSONDecode(string src) {
	string tempStr;
        tempStr = replace(src    , "\\\\", "\\");
        tempStr = replace(tempStr, "\\\"", "\"");
        tempStr = replace(tempStr, "\\/", "/");
        tempStr = replace(tempStr, "\\n", "\n");
        tempStr = replace(tempStr, "\\r", "\r");
        tempStr = replace(tempStr, "\\f", "\f");
        tempStr = replace(tempStr, "\\t", "\t");
        tempStr = replace(tempStr, "\\b", "\b");
	// take care of hex character entities
	// XXX regex is broken in tango 0.99.9 which means this doesn't work right when numbers enter the mix
	tempStr = regrep(tempStr,"\\u[0-9a-fA-F]{4};",(string m) {
		auto cnum = m[3..$-1];
		dchar dnum = hex2dchar(cnum[1..$]);
		return quickUTF8(dnum);
	});
        return tempStr;
}

/// This probably needs documentation.  It looks like it converts a dchar to the necessary length string of chars.
string quickUTF8(dchar dachar) {
	char[] ret;
	if (dachar <= 0x7F) {
		ret.length = 1;
		ret[0] = cast(char) dachar;
	} else if (dachar <= 0x7FF) {
		ret.length = 2;
		ret[0] = cast(char)(0xC0 | (dachar >> 6));
		ret[1] = cast(char)(0x80 | (dachar & 0x3F));
	} else if (dachar <= 0xFFFF) {
		ret.length = 3;
		ret[0] = cast(char)(0xE0 | (dachar >> 12));
		ret[1] = cast(char)(0x80 | ((dachar >> 6) & 0x3F));
		ret[2] = cast(char)(0x80 | (dachar & 0x3F));
	} else if (dachar <= 0x10FFFF) {
		ret.length = 4;
		ret[0] = cast(char)(0xF0 | (dachar >> 18));
		ret[1] = cast(char)(0x80 | ((dachar >> 12) & 0x3F));
		ret[2] = cast(char)(0x80 | ((dachar >> 6) & 0x3F));
		ret[3] = cast(char)(0x80 | (dachar & 0x3F));
	} else {
	    assert(0);
	}
	return cast(string)ret;
}
private dchar hex2dchar (string hex) {
	dchar res;
	foreach(digit;hex) {
		res <<= 4;
		res |= toHVal(digit);
	}
	return res;
}

private dchar toHVal(char digit) {
	if (digit >= '0' && digit <= '9') {
		return digit-'0';
	}
	if (digit >= 'a' && digit <= 'f') {
		return digit-'a';
	}
	if (digit >= 'A' && digit <= 'F') {
		return digit-'A';
	}
	return 0;
}
/*
unittest {
	auto root = new JSONObject();
	auto arr = new JSONArray();
	arr ~= new JSONString("da blue teeths!\"\\");
	root["what is that on your ear?"] = arr;
	root["my pants"] = new JSONString("are on fire");
	root["i am this many"] = new JSONNumber(10.253);
	root["blank"] = new JSONObject();
	string jstr = root.toString;
	writef("Unit Test libDJSON JSON creation...\n");
	writef("Generated JSON string: " ~ jstr ~ "\n");
	writef("Regenerated JSON string: " ~ readJSON(jstr).toString ~ "\n");
	writef("Output using toPrettyString:\n"~root.toPrettyString~"\nEnd pretty output\n");
	assert(jstr == readJSON(jstr).toString);
	writef("Unit Test libDJSON JSON parsing...\n");
	jstr = "{\"firstName\": \"John\",\"lastName\": \"Smith\",\"address\": {\"streetAddress\": \"21 2nd Street\",\"city\": \"New York\",\"state\": \"NY\",\"postalCode\": 10021},\"phoneNumbers\": [{ \"type\": \"home\", \"number\": \"212 555-1234\" },{ \"type\": \"fax\", \"number\": \"646 555-4567\" }],\"newSubscription\": false,\"companyName\": null }";
	writef("Sample JSON string: " ~ jstr ~ "\n");
	jstr = jstr.readJSON().toString;
	auto tmp = jstr.readJSON();
	writef("Parsed JSON string: " ~ jstr ~ "\n");
	writef("Output using toPrettyString:\n"~tmp.toPrettyString~"\nEnd pretty output\n");
	// ensure that the string doesn't mutate after a second reading, it shouldn't
	assert(tmp.toString == jstr);
	// ensure that pretty output still parses properly and doesn't mutate
	jstr = tmp.toPrettyString;
	tmp = jstr.readJSON();
	assert(tmp.toPrettyString == jstr);
	writef("Unit Test libDJSON JSON access...\n");
	writef("Got first name:" ~ tmp["firstName"].toJSONString.get ~ "\n");
	writef("Got last name:" ~ tmp["lastName"].toJSONString.get ~ "\n");
	writef("Unit Test libDJSON opApply interface...\n");
	foreach(obj;tmp["phoneNumbers"]) {
		writef("Got " ~ obj["type"].toJSONString.get ~ " phone number:" ~ obj["number"].toJSONString.get ~ "\n");
	}
	foreach(string name,JSONType obj;tmp) {
		writef("Got element name " ~ name ~ "\n");
	}
	writef("Unit Test libDJSON opIndex interface to ensure breakage where incorrectly used...\n");
	try {
		tmp[5];
		assert(false,"An exception should have been thrown on the line above.");
	} catch (Exception e) {/+shazam! program flow should get here, it is a correct thing+/}
	writef("Testing alternate base container and empty elements...\n");
	assert("[,,]".readJSON().toString == "[null,null,null]");
	jstr = 
" {
	\"realms\": [
		{
			\"type\": \"pve\",
			\"queue\": false,
			\"status\": true,
			\"population\": \"medium\",
			\"name\": \"Aerie Peak\",
			\"slug\": \"aerie-peak\"
		}
	]
}";
	tmp = jstr.readJSON();
	tmp["realms"].toJSONArray().length();
	writef("Testing opIn_r functionality...\n");
	assert("realms" in tmp);
	assert(!("bob" in tmp));
}*/

version(JSON_main) {
	void main(){}
}

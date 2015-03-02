import std.stdio;

import digitalnet.integration;

struct S
{
	uint[] front;
	void popFront(){}
	bool empty;
	size_t precision, dimensionR, dimensionF2;
}

void main()
{
	writeln("Edit source/app.d to start your project.");
	S().integral((real[] x) => x[0]);
}

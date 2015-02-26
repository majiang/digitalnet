import std.stdio, std.conv, std.algorithm;
import digitalnet.implementation;
import digitalnet.integration;

void main(string[] args)
{
	foreach (line; stdin.byLine)
	{
		auto P = line.toShiftedDigitalNet!uint;
		writefln("%s,%.15e", P, P.integral((real[] x) => x.reduce!min));
	}
}

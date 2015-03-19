import std.stdio;
import digitalnet.implementation;


void main(string[] args)
{
	if (1 < args.length && args[1] == "shift")
		foreach (line; stdin.byLine)
		{
			auto P = line.toShiftedDigitalNet!uint;
			auto s = P.randomLinearScramble;
			auto Q = P * s;
			writeln(Q);
		}
	else
		foreach (line; stdin.byLine)
		{
			auto P = line.toDigitalNet!uint;
			auto s = P.randomLinearScramble;
			auto Q = P * s;
			writeln(Q);
		}
}

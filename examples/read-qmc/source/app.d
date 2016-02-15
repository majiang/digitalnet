import std.stdio, std.conv, std.algorithm, std.array, std.string, std.math;
import digitalnet.implementation;
import digitalnet.integration;

void main(string[] args)
{
	auto cs = (args.length == 1) ? [real(1)] :
	(){
		return args[1..$].map!(to!real).array;
	}();
	foreach (line; stdin.byLine)
	{
		write(line.chomp);
		auto P = line.toDigitalNet!uint;
		foreach (c; cs)
			writef(",%.15e", P.integral((real[] x) => (x.reduce!((a, b) => a + b) * c).cos));
		writeln;
	}
}

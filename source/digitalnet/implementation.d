module digitalnet.implementation;

import digitalnet.axiom;
import std.traits, std.algorithm, std.array, std.range, std.typecons, std.random, std.exception, std.string;
import std.conv : to;
debug import std.stdio;

alias LinearScramble = Tuple!(size_t[], size_t);

static assert (isPointSet!(DigitalNet!uint));
static assert (hasPrecision!(DigitalNet!uint));
static assert (isPointSet!(ShiftedDigitalNet!uint));
static assert (hasPrecision!(ShiftedDigitalNet!uint));

mixin template DigitalNetFunctions(U, Size)
{
	const U[][] basis;
	immutable size_t precision, dimensionF2, dimensionR;
	immutable bool bisectable;
	this (in U[][] basis, Precision precision = Precision(U.sizeof << 3))
	{
		this.basis = basis;
		this.precision = precision.getPrecision;
		this.dimensionF2 = basis.length;
		this.dimensionF2.enforce("Zero digital net is not constructible");
		this.dimensionR = basis[0].length;
		foreach (b; basis)
			assert (b.length == dimensionR);
		this.front = new U[dimensionR];
	}
	bool empty;
	U[] front;
	void popFront()
	in
	{
		assert (!empty);
	}
	body
	{
		position += 1;
		if (position >> dimensionF2)
		{
			empty = true;
			return;
		}
		front[] ^= basis[position.bottom_zeros][];
	}
private:
	Size position;
	string _toString() const
	{
		return "%d %d %d %(%(%d %) %)".format(precision, dimensionF2, dimensionR, basis);
	}
}

private U[] scramble(U)(in U[] vector, in size_t[] linearScramble, in size_t precision)
body
{
	static if (is (size_t == ulong))
		enum p = 6, q = 63;
	static if (is (size_t == uint))
		enum p = 5, q = 31;
	auto ret = vector.dup;
	size_t idx;
	foreach (i, ref x; ret)
		foreach (j; 1..precision)
			foreach (U k; 0..j)
			{
				x ^= ((linearScramble[idx >> p] >> (idx & q)) & (x >> j) & 1) << k;
				idx += 1;
			}
	return ret;
}

/// A digital net.
struct DigitalNet(U = uint, Size = GreaterInteger!U)
	if (isUnsigned!U)
{
	mixin DigitalNetFunctions!(U, Size);
	/// Apply a Digital shift.
	ShiftedDigitalNet!(U, Size) opBinary(string op)(in U[] shift) const
		if (op == "+")
	{
		return ShiftedDigitalNet!(U, Size)(basis, shift, Precision(precision));
	}
	DigitalNet!(U, Size) removeShift()
	{
		return this;
	}
	ShiftedDigitalNet!(U, Size)[2] bisect() const
	{
		auto former = ShiftedDigitalNet!(U, Size)(this.basis[1..$], new U[this.dimensionR], Precision(this.precision));
		return [former, former + this.basis[0]];
	}
	public string toString() const
	{
		return _toString();
	}
	/// Apply a linear scramble.
	DigitalNet!(U, Size) opBinary(string op)(in LinearScramble linearScramble) const
		if (op == "*")
	{
		return DigitalNet!(U, Size)(basis.map!(b => b.scramble(linearScramble[0], precision)).array, Precision(precision));
	}
}

/// A digitally shifted digital net.
struct ShiftedDigitalNet(U = uint, Size = GreaterInteger!U)
	if (isUnsigned!U)
{
	mixin DigitalNetFunctions!(U, Size);
	const U[] shift;
	this (in U[][] basis, Precision precision = Precision(U.sizeof << 3))
	{
		this.basis = basis;
		this.precision = precision.getPrecision;
		this.dimensionF2 = basis.length;
		this.dimensionF2.enforce("Zero digital net is not constructible");
		this.dimensionR = basis[0].length;
		foreach (b; basis)
			assert (b.length == dimensionR);
		this.front = new U[dimensionR];
	}
	this (in U[][] basis, in U[] shift, Precision precision = Precision(U.sizeof << 3))
	{
		this (basis, precision);
		this.bisectable = bisectThreshold <= this.dimensionF2;
		this.shift = shift;
		this.front[] = shift[];
	}
	/// Apply a digital shift.
	ShiftedDigitalNet!(U, Size) opBinary(string op)(in U[] shift) const
		if (op == "+")
	{
		auto newShift = new U[dimensionR];
		foreach (i, ref s; newShift)
			s = this.shift[i] ^ shift[i];
		return ShiftedDigitalNet!(U, Size)(basis, newShift, Precision(precision));
	}
	/// Remove a digital shift.
	DigitalNet!(U, Size) removeShift() const
	{
		return DigitalNet!(U, Size)(basis, Precision(precision));
	}
	ShiftedDigitalNet!(U, Size)[2] bisect() const
	{
		auto former = ShiftedDigitalNet!(U, Size)(this.basis[1..$], this.shift, Precision(this.precision));
		return [former, former + this.basis[0]];
	}
	string toString() const
	{
		return _toString() ~ " %(%d %)".format(shift);
	}
	/// Apply a linear scramble.
	ShiftedDigitalNet!(U, Size) opBinary(string op)(in LinearScramble linearScramble) const
		if (op == "*")
	{
		return ShiftedDigitalNet!(U, Size)(basis.map!(b => b.scramble(linearScramble[0], precision)).array, shift.scramble(linearScramble[0], precision), Precision(precision));
	}
}

private U[] getShift(U)(ref U[][] basis, in size_t dimB, in size_t dimR)
{
	if (basis.length == dimB)
	{
		stderr.writeln("run-time warning: add a zero shift");
		return new U[dimR];
	}
	if (basis.length == dimB + 1)
	{
		auto s = basis[$-1];
		basis.length -= 1;
		return s;
	}
	assert (false);
}

private U[][] noShift(U)(U[][] basis, in size_t dimB)
{
	if (basis.length == dimB + 1)
	{
		stderr.writefln("run-time warning: ignoring shift, [%(%d %)]", basis[dimB..$][0]);
		return basis[0..$-1];
	}
	if (basis.length == dimB)
		return basis;
	assert (false);
}


private U[][] readDigitalNetParams(U)(const(char)[][] buf, out size_t prec, out size_t dimB, out size_t dimR)
{
	prec = buf[0].to!size_t;
	dimB = buf[1].to!size_t;
	dimR = buf[2].to!size_t;
	return buf[3..$].map!(to!U).array.chunks(dimR).array;
}

/// Read a digital net from a string.
DigitalNet!U toDigitalNet(U = uint)(const(char)[] x)
{
	size_t prec, dimB, dimR;
	auto basis = x.strip.split(',')[0].split.readDigitalNetParams!U(prec, dimB, dimR);
	return DigitalNet!U(noShift(basis, dimB), Precision(prec));
}

/// Read a digitally shifted digital net from a string.
ShiftedDigitalNet!U toShiftedDigitalNet(U = uint)(const(char)[] x)
{
	size_t prec, dimB, dimR;
	auto basis = x.strip.split(',')[0].split.readDigitalNetParams!U(prec, dimB, dimR);
	auto shift = getShift(basis, dimB, dimR);
	return ShiftedDigitalNet!U(basis, shift, Precision(prec));
}

template GreaterInteger(U)
	if (isUnsigned!U)
{
	import std.bigint;
	static if (U.sizeof < ulong.sizeof)
		alias GreaterInteger = ulong;
	else
		alias GreaterInteger = BigInt;
}

immutable(size_t) getPrecision(Precision n)
{
	return cast(size_t)n;
}
immutable(size_t) getDimensionR(DimensionR s)
{
	return cast(size_t)s;
}
immutable(size_t) getDimensionF2(DimensionF2 m)
{
	return cast(size_t)m;
}

alias Precision = Typedef!(size_t, 0, "prec");

alias DimensionR = Typedef!(size_t, 0, "dimR");

alias DimensionF2 = Typedef!(size_t, 0, "dimB");

/// Construct a digital net by uniform random choice of its basis.
DigitalNet!U randomDigitalNet(U = uint)(Precision precision, DimensionR dimensionR, DimensionF2 dimensionF2)
	if (isUnsigned!U)
{
	immutable s = dimensionR.getDimensionR;
	auto basis = randomVector!U(precision.getPrecision, s * dimensionF2.getDimensionF2).chunks(s).array;
	return DigitalNet!U(basis, precision);
}

/// Uniformly and randomly pick a digital shift.
auto randomDigitalShift(S)(S P)
	if (is (S == DigitalNet!(U, Size), U, Size) || is (S == ShiftedDigitalNet!(U, Size), U, Size))
{
	alias U = ElementType!(typeof (P.front));
	return randomVector!U(P.precision, P.dimensionR);
}

/// ditto
U[] randomDigitalShift(U)(Precision precision, DimensionR dimensionR)
	if (isUnsigned!U)
{
	return randomVector!U(precision.getPrecision, dimensionR.getDimensionR);
}

/// Uniformly and randomly pick a linear scramble.
auto randomLinearScramble(S)(S P)
	if (is (S == DigitalNet!(U, Size), U, Size) ||
		is (S == ShiftedDigitalNet!(U, Size), U, Size))
{
	immutable size_t
		wordSize = size_t.sizeof << 3,
		numBits = P.dimensionR * (P.precision * (P.precision - 1) / 2),
		backLength = numBits / wordSize + (numBits % wordSize ? 1 : 0);
	import std.bitmanip : BitArray;
	return LinearScramble(randomVector!size_t(wordSize, backLength), numBits);
}


private:

U[] randomVector(U)(size_t precision, size_t length)
	if (isUnsigned!U)
{
	auto ret = new U[length];
	randomVector(precision, ret);
	return ret;
}

void randomVector(U)(size_t precision, U[] buffer)
{
	randomVector(buffer);
	if (auto d = (U.sizeof << 3) - precision)
		foreach (ref e; buffer)
			e >>= d;
}

void randomVector(U)(U[] buffer)
{
	foreach (ref e; buffer)
		e = uniform!U;
}

auto bottom_zeros(Size)(Size x)
{
	assert (x);
	size_t ret;
	while ((x & 1) == 0)
	{
		x >>= 1;
		ret += 1;
	}
	return ret;
}

enum size_t bisectThreshold = 10;

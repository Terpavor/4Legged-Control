#ifndef SIMPLE_ROBOT_PROTOCOL_H
#define SIMPLE_ROBOT_PROTOCOL_H

//#include <QtGlobal>		// ?
#include <QAbstractSocket>	// used in Packet::write() and constructReceivedPacket();
#include <QDataStream>		// used everywhere
#include <QSharedPointer>	// used in constructReceivedPacket();
//#include <type_traits>	// ?


struct Packet
{
	enum class Type : quint8
	{
		command,
		telemetry,
		log
	};


	quint32 size;


	Packet(quint32 size = 0)	: size(size) {}
	virtual ~Packet() {}

	virtual Type getType() = 0;

	void write(QAbstractSocket * const socket);

	virtual void scan(QDataStream & in) = 0;
	virtual void print(QDataStream & out) const = 0;
};

struct CommandPacket : public Packet
{
	QString command;

	CommandPacket(quint32 size = 0) : Packet(size) {}

	virtual Type getType()
	{
		return Type::command;
	}

	virtual void scan(QDataStream & in)
	{
		in >> command;
	}
	virtual void print(QDataStream & out) const
	{
		out << command;
	}
};

struct TelemetryPacket : public Packet
{

	static const quint16 timestamp_count = 1, servo_count = 12, battery_count = 2, leg_count = 4, quaternion_size = 4, vector_size = 3;

	qint64	timestamp		[timestamp_count];
	float	servo_position	[servo_count];
	float	battery_voltage	[battery_count];
	bool	ground_contact	[leg_count];
	float	orientation		[quaternion_size];
	float	acceleration	[vector_size];
	float	gravity			[vector_size];


	TelemetryPacket(quint32 size = 0) : Packet(size) {}

	virtual Type getType()
	{
		return Type::telemetry;
	}

	virtual void scan(QDataStream & in)
	{
		for(int i = 0; i < timestamp_count;	i++)	in >> timestamp			[i];
		for(int i = 0; i < servo_count;     i++)	in >> servo_position	[i];
		for(int i = 0; i < battery_count;   i++)	in >> battery_voltage	[i];
		for(int i = 0; i < leg_count;		i++)	in >> ground_contact	[i];
		for(int i = 0; i < quaternion_size;	i++)	in >> orientation		[i];
		for(int i = 0; i < vector_size;		i++)	in >> acceleration		[i];
		for(int i = 0; i < vector_size;		i++)	in >> gravity			[i];
	}
	virtual void print(QDataStream & out) const
	{
		for(int i = 0; i < timestamp_count;	i++)	out << timestamp		[i];
		for(int i = 0; i < servo_count;     i++)	out << servo_position	[i];
		for(int i = 0; i < battery_count;   i++)	out << battery_voltage	[i];
		for(int i = 0; i < leg_count;		i++)	out << ground_contact	[i];
		for(int i = 0; i < quaternion_size; i++)	out << orientation		[i];
		for(int i = 0; i < vector_size;     i++)	out << acceleration		[i];
		for(int i = 0; i < vector_size;     i++)	out << gravity			[i];
	}
	virtual void print(QTextStream & out) const
	{
		for(int i = 0; i < timestamp_count;	i++)	out << QString::number(timestamp		[i]) << '\t';
		for(int i = 0; i < servo_count;     i++)	out << QString::number(servo_position	[i]) << '\t';
		for(int i = 0; i < battery_count;   i++)	out << QString::number(battery_voltage	[i]) << '\t';
		for(int i = 0; i < leg_count;		i++)	out << QString::number(ground_contact	[i]) << '\t';
		for(int i = 0; i < quaternion_size; i++)	out << QString::number(orientation		[i]) << '\t';
		for(int i = 0; i < vector_size;     i++)	out << QString::number(acceleration		[i]) << '\t';
		for(int i = 0; i < vector_size;     i++)	out << QString::number(gravity			[i])
														<< (i < vector_size-1 ? '\t' : '\n');
	}
	friend QTextStream & operator << ( QTextStream & out, const TelemetryPacket & packet )
	{
		packet.print(out);
		return out;
	}


};

struct LogPacket : public Packet
{
	QString message;

	LogPacket(quint32 size = 0) : Packet(size) {}

	virtual Type getType()
	{
		return Type::log;
	}

	virtual void scan(QDataStream & in)
	{
		in >> message;
	}
	virtual void print(QDataStream & out) const
	{
		out << message;
	}

};



#define DEF_STREAM_OP(T)														\
	inline QDataStream & operator >> ( QDataStream & in, T & packet )			\
	{																			\
		packet.scan(in);														\
		return in;																\
	}																			\
	inline QDataStream & operator << ( QDataStream & out, const T & packet )	\
	{																			\
		packet.print(out);														\
		return out;																\
	}
	DEF_STREAM_OP(Packet)
	DEF_STREAM_OP(CommandPacket)
	DEF_STREAM_OP(TelemetryPacket)
	DEF_STREAM_OP(LogPacket)
#undef DEF_STREAM_OP



QSharedPointer<Packet> constructReceivedPacket(QAbstractSocket *socket);

#endif // SIMPLE_ROBOT_PROTOCOL_H

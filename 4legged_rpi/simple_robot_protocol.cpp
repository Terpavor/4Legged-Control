#include "simple_robot_protocol.h"

void Packet::write(QAbstractSocket * const socket)
{
	QByteArray block;
	QDataStream out(&block, QIODevice::WriteOnly);
	out.setVersion(QDataStream::Qt_5_3);

	// skip payload size bytes and write packet type
	out << (decltype(size))0;
	out << (std::underlying_type<Type>::type)getType();

	// write all packet data
	print(out);

	// return to packet size and write payload size
	out.device()->seek(0);
	out << (quint32)(block.size() - sizeof(size) - sizeof(Type));


	// write packet to socket and start sending immediately
	socket->write(block);
	socket->flush();

	qDebug() << block.toHex();
}

QSharedPointer<Packet> constructReceivedPacket(QAbstractSocket *socket)
{
	static quint8	packet_type;
	static quint32	packet_size = 0;

	QDataStream in(socket);
	in.setVersion(QDataStream::Qt_5_3);

	if(packet_size == 0)
	{
		if ( socket->bytesAvailable() < sizeof(quint8) + sizeof(quint32) )
		{
			qDebug() << "RET1";
			return QSharedPointer<Packet>(0); // could be NULL/nullptr, but Qt 5.3 is too old
		}
		in >> packet_size; // 4 bytes
		in >> packet_type; // 1 byte
	}

	if (socket->bytesAvailable() < packet_size || in.atEnd())
	{
		qDebug() << "RET2, socket->bytesAvailable() = " << socket->bytesAvailable() << ", packet_size = " << packet_size;
		return QSharedPointer<Packet>(0); // could be NULL/nullptr, but Qt 5.3 is too old
	}

	packet_size = 0;

	QSharedPointer<Packet> tmp;

	switch(Packet::Type(packet_type)) {
	case Packet::Type::command :
		tmp.reset(new CommandPacket(packet_size));
		break;
	case Packet::Type::telemetry :
		tmp.reset(new TelemetryPacket(packet_size));
		break;
	case Packet::Type::log :
		tmp.reset(new LogPacket(packet_size));
		break;
	default:
		qDebug() << "RET3, packet_type = " << packet_type;
		return QSharedPointer<Packet>(0); // could be NULL/nullptr, but Qt 5.3 is too old
	}

	in >> *tmp;

	return tmp;
}

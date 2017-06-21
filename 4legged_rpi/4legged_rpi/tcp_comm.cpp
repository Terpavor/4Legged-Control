#include <QtGlobal>
#include <QDateTime>
#include <QString>
#include <QTimer>

#include "tcp_comm.h"



TcpCommunication::TcpCommunication(uint16_t port_number)
{
	bool success = server.listen(QHostAddress::Any, port_number);
	if(!success)
	{
		qDebug() << "Server Error: unable to start the server:"
				 << server.errorString();
		server.close();
		return;
	}

	connect(&server, &QTcpServer::newConnection,
			 this,	 &TcpCommunication::createNewConnection);

	qDebug() << "CONSTRUCTOR END";


	qsrand(1);
	qrand();
	qrand();

	for(int i = 0; i < packet_telemetry_out.servo_count;		i++)	packet_telemetry_out.servo_position	[i] = (qrand()%1800-900)/10.0;
	for(int i = 0; i < packet_telemetry_out.battery_count;		i++)	packet_telemetry_out.battery_voltage[i] = (qrand()%200+900)/100.0;
	for(int i = 0; i < packet_telemetry_out.leg_count;			i++)	packet_telemetry_out.ground_contact	[i] = qrand()%2;
	for(int i = 0; i < packet_telemetry_out.quaternion_size;	i++)	packet_telemetry_out.orientation	[i] = (qrand()%1800-900)/10.0;
	for(int i = 0; i < packet_telemetry_out.vector_size;		i++)	packet_telemetry_out.acceleration	[i] = (qrand()%100-50)/100.0;
	for(int i = 0; i < packet_telemetry_out.vector_size;		i++)	packet_telemetry_out.gravity		[i] = qrand()%2;
}

void TcpCommunication::readData()
{
	qDebug() << "READ DATA1";

	if(socket == NULL)
		return;

	qDebug() << "READ DATA2";

	packet_in = constructReceivedPacket(socket);

	qDebug() << "READ DATA3";

	if(packet_in == NULL)
		return;

	qDebug() << "READ DATA4";


	QByteArray buffer;
	QDataStream stream(&buffer, QIODevice::WriteOnly);
	qDebug() << "READ DATA5";
	stream << *packet_in;
	qDebug() << "READ DATA6";
	qDebug() << buffer.toHex();

	if(packet_in->getType()==Packet::Type::command)
	{
		emit receivedCommandPacket(
					qSharedPointerCast<CommandPacket>(packet_in)->command);
	}

	// do something

	/*QDataStream in(socket);
	in.setVersion(QDataStream::Qt_5_3);

	qDebug() << "block_size = " << block_size;
	if (block_size == 0)
	{
		qDebug() << "socket->bytesAvailable() = " << socket->bytesAvailable();
		// Relies on the fact that QDataStream format streams a quint32 into sizeof(quint32) bytes
		if (socket->bytesAvailable() < (int)(sizeof(quint32) + sizeof(quint8)))
		{
			qDebug() << "RET1";
			return;
		}
		in >> block_size; // 4 bytes
		in >> packet_type; // 1 byte
		qDebug() << "new block_size = " << block_size;
	}

	if (socket->bytesAvailable() < block_size || in.atEnd())
	{
		qDebug() << "RET2" << socket->bytesAvailable() << " " << block_size;
		return;
	}

	QByteArray block;
	//in >> block;
	char *temp = new char[block_size];
	quint32 bytes_read = in.readRawData(temp, block_size);
	block.append(temp, bytes_read);
	delete [] temp;


	qDebug() << block.toHex();

	block_size -= bytes_read;


	//QByteArray buffer = socket->readLine();
	//qDebug() << buffer;*/

	sendData();
}
void TcpCommunication::sendData()
{
	qDebug() << "SEND DATA";

	if(socket->state() != QTcpSocket::ConnectedState)
		return;

	packet_telemetry_out.timestamp[0] = QDateTime::currentDateTime().toMSecsSinceEpoch();
	packet_telemetry_out.write(socket);

	//QDateTime datetime = datetime.currentDateTime();
	//packet_log_out.message = datetime.toString("dd.MM.yyyy hh:mm:ss.zzz") +
	//		" | Onboard Computer | INFO | I'm alive";
	//packet_log_out.write(socket);


	QTimer::singleShot(2000, this, SLOT(sendData()));

	/*
	QDataStream out(&block, QIODevice::WriteOnly);
	out.setVersion(QDataStream::Qt_5_3);

	static bool i = 0;


	//socket->write("some telemetry for command center\n");
	//socket->flush();

	//socket->write(block);

	out << (quint32)0;
	out << (quint8)0;
	out << i;
	i++;
	out.device()->seek(0);
	out << (quint32)(block.size() - sizeof(quint32) - sizeof(quint8));

	socket->write(block);
	socket->flush();


	qDebug() << "SEND DATA " << block.toHex();

	//socket->write( QStringLiteral("some command for robot %1").arg(i++).toStdString().c_str() );
	//socket->flush();
	*/
}

void TcpCommunication::createNewConnection()
{
	qDebug() << "NEW CONNECTION";

	socket = server.nextPendingConnection();

	if(socket->state() == QTcpSocket::ConnectedState)
	{
		connect(socket, &QTcpSocket::readyRead,
				this,	&TcpCommunication::readData);
	}


	sendData();
}
















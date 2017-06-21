
#include "tcp_client.h"
#include <QTimer>


TcpClient::TcpClient(const char address[], uint16_t port_number)
	: address(address)
	, port_number(port_number)
	, socket(new QTcpSocket(this))
	, packets_sent(0)
	, packets_received(0)
{
	connect( socket, &QTcpSocket::readyRead,
			 this,	 &TcpClient::readData );

	//connect( socket, &QTcpSocket::disconnected,
	//		 this,	 &TcpClient::reconnectToServer );

	connect( socket, QOverload<QTcpSocket::SocketError>::of(&QTcpSocket::error),
			 this,	 &TcpClient::showErrorAndReconnect);

	connect(&reconnect_timer, &QTimer::timeout,
			 this, &TcpClient::connectToServer);

	qDebug() << "CONSTRUCTOR END";
}

QString TcpClient::getAddress()				{ return address; }
quint16 TcpClient::getPortNumber()			{ return port_number; }
void TcpClient::setAddress(QString s)		{ address = s; }
void TcpClient::setPortNumber(quint16 n)	{ port_number = n; }

void TcpClient::readData()
{
	qDebug() << "READ DATA";

	//QByteArray buffer = socket->readLine();


	packet_in = constructReceivedPacket(socket);

	if(packet_in == NULL)
		return;

	packets_received++;
	emit updateClientState(true, packets_sent, packets_received);

	if(packet_in->getType()==Packet::Type::log)
	{
		qDebug() << (qSharedPointerCast<LogPacket>(packet_in))->message.toStdString().c_str();
		emit receivedLogPacket(
					qSharedPointerCast<LogPacket>(packet_in)->message );
	}
	if(packet_in->getType()==Packet::Type::telemetry)
	{
		emit receivedTelemetryPacket(
					*qSharedPointerCast<TelemetryPacket>(packet_in) );
	}

	// do something
	QByteArray buffer;
	QDataStream stream(&buffer, QIODevice::ReadWrite);
	stream << *packet_in;
	//qDebug() << buffer.toHex();

/*
	QDataStream in(socket);
	in.setVersion(QDataStream::Qt_5_3);

	qDebug() << "block_size = " << block_size;
	if (block_size == 0)
	{
		qDebug() << "socket->bytesAvailable() = " << socket->bytesAvailable();
		// Relies on the fact that QDataStream format streams a quint32 into sizeof(quint32) bytes
		if (socket->bytesAvailable() < (int)sizeof(quint32))
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





	//QByteArray ba;
	//in >> ba;

	//ba.resize(100);
	//in.readRawData(ba.data(), 100);

	//qDebug() << ba; */

	//QTimer::singleShot(2000, this, &TcpClient::sendData);
}
void TcpClient::sendData()
{
	qDebug() << "SEND DATA";

	if(socket->state() != QTcpSocket::ConnectedState)
		return;


	qDebug() << packet_out.command;

	packet_out.write(socket);

	packets_sent++;
	emit updateClientState(true, packets_sent, packets_received);
	/*
	static int i = 0;


	QByteArray block;
	QDataStream out(&block, QIODevice::WriteOnly);
	out.setVersion(QDataStream::Qt_5_3);

	out << (quint32)0;
	out << (quint8)0;
	out << i++;
	out.device()->seek(0);
	out << (quint32)(block.size() - sizeof(quint32) - sizeof(quint8));

	socket->write(block);
	socket->flush();


	qDebug() << "SEND DATA " << block.toHex();

	//socket->write( QStringLiteral("some command for robot %1").arg(i++).toStdString().c_str() );
	//socket->flush();
	*/
}
void TcpClient::sendString(const QString &str)
{
	packet_out.command = str;

	sendData();
}

void TcpClient::connectToServer()
{
	qDebug() << "CONNECTING_TO_SERVER";
	emit connecting();

	socket->connectToHost(address, port_number);

	bool is_connected = socket->waitForConnected(100); // msecs
	if(is_connected)
	{
		qDebug() << "CONNECTED!";
		reconnect_timer.stop();
		emit connected();
		emit updateClientState(true, packets_sent, packets_received);
	}
	else
	{
		qDebug() << "CONNECTION FAILED!";
		if(!reconnect_timer.isActive())
		{
			reconnect_timer.setInterval(1000);
			reconnect_timer.start();
		}
	}
}
/*
void TcpClient::reconnectToServer()
{
	qDebug() << "RECONNECT!";
	reconnect_timer.singleShot(0, this, &TcpClient::connectToServer);

	// http://doc.qt.io/qt-5/qabstractsocket.html#error
}*/
void TcpClient::disconnectFromServer()
{
	qDebug() << "DISCONNECT";
	socket->disconnectFromHost();
	reconnect_timer.stop();

	emit disconnected();
	emit updateClientState(false, packets_sent, packets_received);
}

void TcpClient::showErrorAndReconnect(QAbstractSocket::SocketError socketError)
{
	// http://doc.qt.io/qt-5/qabstractsocket.html#error
	if(!reconnect_timer.isActive())
		reconnect_timer.singleShot(0, this, &TcpClient::connectToServer);
	qDebug() << "ERROR " << socketError;
}









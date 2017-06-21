#ifndef TCP_COMM_H
#define TCP_COMM_H

#include <QObject>

#include <QTcpServer>
#include <QTcpSocket>
#include <QDataStream>
#include <QSharedPointer>
#include "simple_robot_protocol.h"

class TcpCommunication : public QObject
{
	Q_OBJECT

	QTcpServer  server;
	QTcpSocket *socket;

	QSharedPointer<Packet>	packet_in;
	TelemetryPacket			packet_telemetry_out;
	LogPacket				packet_log_out;

public:
	TcpCommunication(uint16_t port_number);

signals:
	void receivedCommandPacket(QString);

public slots:
	void createNewConnection(); // connected to QTcpServer::newConnection()
	void readData(); // connected to QTcpSocket::readyRead() in createNewConnection()
	void sendData();
};

#endif // TCP_COMM_H

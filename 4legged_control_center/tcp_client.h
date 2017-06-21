#ifndef TCP_COMM_H
#define TCP_COMM_H

#include <QObject>

#include <QHostAddress>
#include <QTcpSocket>
#include <QDataStream>
#include <QTimer>

#include "simple_robot_protocol.h"

class TcpClient : public QObject
{
	Q_OBJECT

	QString		address;
	quint16		port_number;

	QTcpSocket			  *socket;
	QSharedPointer<Packet> packet_in;
	CommandPacket		   packet_out;

	quint16		packets_sent, packets_received;

	QTimer reconnect_timer;

public:
	TcpClient(const char address[], uint16_t port_number);

	QString getAddress();
	quint16 getPortNumber();
	void setAddress(QString);
	void setPortNumber(quint16);


signals:
	void connecting();
	void connected();
	void disconnected();
	void updateClientState(bool, quint16, quint16);

	void receivedLogPacket(const QString);
	void receivedTelemetryPacket(TelemetryPacket);

private slots:
	void readData();
	void sendData();
public slots: // public - to use with lambda
	void sendString(const QString &);

	//LogPacket readLogPacket();
	//TelemetryPacket readTelemetryPacket();
	//void sendCommandPacket(CommandPacket);

public slots:
	void connectToServer();
	void disconnectFromServer();
	void showErrorAndReconnect(QAbstractSocket::SocketError);
};

#endif // TCP_COMM_H

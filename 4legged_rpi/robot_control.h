#ifndef ROBOT_CONTROL_H
#define ROBOT_CONTROL_H

#include <QObject>
#include <QList>
#include <QVector>
#include <QDataStream>
#include <QProcess>

#include "tcp_comm.h"

class RobotControl : public QObject
{
    Q_OBJECT

	static const quint16 servo_count = 12, battery_count = 1, leg_count = 1;

	TcpCommunication *server;

	QProcess v4l2rtspserver_process;

	struct TelemetryPacket
	{
		float servo_position[servo_count];
		float battery_voltage[battery_count];
		bool ground_contact[leg_count];
		float orientation[4];
		float acceleration[3];
		float gravity[3];
		static constexpr quint16 getCount()
		{
			return servo_count+battery_count+leg_count+4+3+3;
		}
	} t_packet;

	friend QDataStream & operator << ( QDataStream & out, const TelemetryPacket & packet )
	{
		for(int i = 0; i < servo_count;     i++)	out << packet.servo_position[i];
		for(int i = 0; i < battery_count;   i++)	out << packet.battery_voltage[i];
		for(int i = 0; i < leg_count;       i++)	out << packet.ground_contact[i];
		for(int i = 0; i < 4;               i++)	out << packet.orientation[i];
		for(int i = 0; i < 3;               i++)	out << packet.acceleration[i];
		for(int i = 0; i < 3;               i++)	out << packet.gravity[i];
		return out;
	}

	friend QDataStream & operator >> ( QDataStream & in, TelemetryPacket & packet )
	{
		for(int i = 0; i < servo_count;     i++)	in >> packet.servo_position[i];
		for(int i = 0; i < battery_count;   i++)	in >> packet.battery_voltage[i];
		for(int i = 0; i < leg_count;       i++)	in >> packet.ground_contact[i];
		for(int i = 0; i < 4;               i++)	in >> packet.orientation[i];
		for(int i = 0; i < 3;               i++)	in >> packet.acceleration[i];
		for(int i = 0; i < 3;               i++)	in >> packet.gravity[i];
		return in;
	}

	struct InternalPacket
    {
        float servo_position[servo_count];
        float battery_voltage[battery_count];
        bool ground_contact[leg_count];
        float orientation[4];
        float acceleration[3];
        float gravity[3];
		static constexpr quint16 getCount()
		{
			return servo_count+battery_count+leg_count+4+3+3;
		}
    } packet;

	QList<QVector<float>> trajectory;



public:

	RobotControl();

signals:
    void serialPacketParsed();

public slots:
    void parseSerialPacket(QString);
	void parseTcpPacket(QString);
	void sendServoData(const QVector<float> &);
	void sendNextServoData();

};

#endif // ROBOT_CONTROL_H

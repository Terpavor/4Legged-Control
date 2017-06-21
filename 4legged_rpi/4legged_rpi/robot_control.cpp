
#include <QDebug>
#include <QSerialPortInfo>
#include <QByteArray>

#include "robot_control.h"

RobotControl::RobotControl()
	: server(new TcpCommunication(33333))
{
	trajectory.reserve(1000);

	connect(this,	&RobotControl::serialPacketParsed,
			this,	&RobotControl::sendNextServoData);

	connect(server, &TcpCommunication::receivedCommandPacket,
			this,	&RobotControl::parseTcpPacket);
}

void RobotControl::parseSerialPacket(QString str)
{
    QStringList str_list = str.split(QRegExp("\\s+"), QString::SkipEmptyParts); // QRegExp("\\s+") == QChar::isSpace()

	qDebug() << str << endl << str_list;

	if(str_list.length() < InternalPacket::getCount())
	{
		qDebug() << "invalid telemetry format(got" << str_list.length() << "values, not"
				 << InternalPacket::getCount()  <<  "):" << str << str_list.length() << endl;
        return;
    }

    int j = 0;
	for(int i = 0; i < servo_count;     i++, j++)   packet.servo_position[i]	= str_list[j].toFloat();
    for(int i = 0; i < battery_count;   i++, j++)   packet.battery_voltage[i]   = str_list[j].toFloat();
    for(int i = 0; i < leg_count;       i++, j++)   packet.ground_contact[i]    = str_list[j].toInt();
    for(int i = 0; i < 4;               i++, j++)   packet.orientation[i]       = str_list[j].toFloat();
    for(int i = 0; i < 3;               i++, j++)   packet.acceleration[i]      = str_list[j].toFloat();
    for(int i = 0; i < 3;               i++, j++)   packet.gravity[i]           = str_list[j].toFloat();

	emit serialPacketParsed();
}

void RobotControl::parseTcpPacket(QString str)
{
	qDebug() << "received command:" << str;

	if(str=="streaming start")
	{
		qDebug() << "streaming start command is executed" << str;

		v4l2rtspserver_process.start("/bin/bash",
									 QStringList()
										<< "/home/pi/share/bash_scripts/streaming_control.sh");

		connect(&v4l2rtspserver_process,	&QProcess::readyReadStandardOutput,
				[this]
				{
					qDebug() << QString( v4l2rtspserver_process.readAllStandardOutput() );
				});
		connect(&v4l2rtspserver_process,	&QProcess::readyReadStandardError,
				[this]
				{
					qDebug() << QString( v4l2rtspserver_process.readAllStandardError() );
				});

	}
	else if(str=="streaming stop")
	{
		v4l2rtspserver_process.terminate();
	}
	else if(str=="vnc start")
	{
		QProcess::startDetached("/bin/bash",
								QStringList()
									<< "/home/pi/share/bash_scripts/vnc_control.sh"
									<< "start");
	}
	else if(str=="vnc stop")
	{
		QProcess::startDetached("/bin/bash",
								QStringList()
									<< "/home/pi/share/bash_scripts/vnc_control.sh"
									<< "stop");
	}
	else if(str=="move")
	{

	}
	else if(str=="stop")
	{

	}
}

void RobotControl::sendServoData(const QVector<float> &servo_data)
{
	QByteArray servo_str;
	servo_str.reserve(100);

	for(size_t i = 0; i < servo_count; i++)
		servo_str += QStringLiteral("s%1v%2").arg(i).arg(servo_data[i]);

	servo_str.append('\n');

	qDebug() << servo_str << endl;
}

void RobotControl::sendNextServoData()
{
	if(!trajectory.isEmpty())
		sendServoData(trajectory.takeFirst());
	else
		qDebug() << "trajectory is empty" << endl;
}







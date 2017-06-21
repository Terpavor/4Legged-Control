#include <QCoreApplication>
#include <QDebug>
#include <QTextCodec>
#include <QDateTime>
#include <QProcess>

#include "tcp_comm.h"
#include "serial_comm.h"
#include "robot_control.h"

#define Q_REMOTEOBJECTS_EXPORT

int main(int argc, char *argv[])
{
	QCoreApplication a(argc, argv);

	RobotControl r;
	//TcpCommunication t(33333);


#if 0
    SerialCommunication s;
    RobotControl r;

    qDebug() << QDateTime::currentMSecsSinceEpoch();//.toString();

    QObject::connect(&s, &SerialCommunication::dataSeparated, &r, &RobotControl::parseSerialPacket);
    //QObject::connect(&s, SIGNAL(dataSeparated(QStringList)), &r, SLOT(parseSerialData(QStringList)));

    s.readData();
    s.readData();
    s.readData();
    s.readData();
    s.readData();
    s.readData();
    s.readData();
    s.readData();

    QVector<float> atata(12);
    for(int i=0;i<atata.count();i++)
    {
        atata[i] = 80+i/2.0;
    }
    r.sendServoData(atata);

    //s.openSerialPort();
#endif
    return a.exec();
}

//#include "main.moc"

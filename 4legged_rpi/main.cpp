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


    return a.exec();
}

//#include "main.moc"


#include <QDebug>
#include <QSerialPortInfo>
#include <QByteArray>

#include "serial_comm.h"

SerialCommunication::SerialCommunication() : unfinished_line("")
{
    //serial = new QSerialPort(this);

    connect(&serial, &QSerialPort::readyRead, this, &SerialCommunication::readData);

    time.start();

    timens.start();
}

void SerialCommunication::openSerialPort()
{
    const QList<QSerialPortInfo> serial_list = QSerialPortInfo::availablePorts();

    foreach(QSerialPortInfo it, serial_list)
        qDebug() << it.portName();

    serial.setPortName      ("COM7");
    serial.setBaudRate      (250000);
    serial.setDataBits      (QSerialPort::Data8);
    serial.setParity        (QSerialPort::NoParity);
    serial.setStopBits      (QSerialPort::OneStop);
    serial.setFlowControl   (QSerialPort::NoFlowControl);


    bool is_open = serial.open(QIODevice::ReadWrite);
    if (is_open)
    {

	}
}


void SerialCommunication::readData()
{
    qDebug() << "timer: " << time.elapsed();
    time.restart();
    qDebug() << "timer: " << timens.nsecsElapsed();
    timens.restart();

	// dummy
    QString str_from_mega = "0 1 2 3.1 3.2 3.3 3.4 4.1 4.2 4.3 5.1 5.2 5.3\r\n";
    //QString str_from_mega = serial.readAll();

    if(str_from_mega.isEmpty())
        return;

    // "str1\nstr2\nstr3\n" -> {"str1","str2","str3",""}
    // "str1\nstr2\nst"     -> {"str1","str2","st"}
    QStringList str_list = str_from_mega.split( QRegExp("(\r\n|\r|\n)") ); // "\r" or "\n" or "\r\n"

    // unfinished_line == "" (clear line) - then do nothing
    // unfinished_line == "st", str_list.first() == "r3" -> str_list.first() = "str3"
    str_list.first().prepend(unfinished_line);

    // will be "" (clear line) if last line ends with "\r" or "\n" or "\r\n"
    // else some unfinished line that we need to prepend in next readData() call
    unfinished_line = str_list.takeLast();

    foreach(const QString &str, str_list)
        emit dataSeparated(str);

	qDebug("end");
}


void SerialCommunication::sendData(const QByteArray &data)
{
    serial.write(data);
}

void SerialCommunication::closeSerialPort()
{

}

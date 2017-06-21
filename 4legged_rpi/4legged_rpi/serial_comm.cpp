
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

    /*
    SettingsDialog::Settings p = settings->settings();
    serial->setPortName(p.name);
    serial->setBaudRate(p.baudRate);
    serial->setDataBits(p.dataBits);
    serial->setParity(p.parity);
    serial->setStopBits(p.stopBits);
    serial->setFlowControl(p.flowControl);
    if (serial->open(QIODevice::ReadWrite)) {
        console->setEnabled(true);
        console->setLocalEchoEnabled(p.localEchoEnabled);
        ui->actionConnect->setEnabled(false);
        ui->actionDisconnect->setEnabled(true);
        ui->actionConfigure->setEnabled(false);
        showStatusMessage(tr("Connected to %1 : %2, %3, %4, %5, %6")
                          .arg(p.name).arg(p.stringBaudRate).arg(p.stringDataBits)
                          .arg(p.stringParity).arg(p.stringStopBits).arg(p.stringFlowControl));
    } else {
        QMessageBox::critical(this, tr("Error"), serial->errorString());

        showStatusMessage(tr("Open error"));
    }
    */
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



#if 0


    static QByteArray ba, ba2;
    QStringList str_list;
    ba.append( serial->readAll() );

    int i = 0, str_start = 0, str_end = 0;



    bool got_eol = false;
    for(int i = 0, j = 0; i < ba.length(); i++)
    {
        if(ba[i]=='\r' || ba[i]=='\n')
        {
            str_list = ba.mid(j,i-j);
            ++i;
            if(ba[i+1]=='\r' || ba[i+1]=='\n')
            {

            }
            j = i;
        }
        else if(got_eol)
        {

            qDebug() << "before:" << ba;
            ba.remove(0, i);
            qDebug() << "after:" << ba << endl;


            qDebug() << ba2 << endl;
        }
    }

    return;

    char buffer[1024];
    qint64 lineLength = serial->readLine(buffer, sizeof(buffer));
    qDebug()  << buffer << endl;

#endif
}


void SerialCommunication::sendData(const QByteArray &data)
{
    serial.write(data);
}

void SerialCommunication::closeSerialPort()
{

}
